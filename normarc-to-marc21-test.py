#!/usr/bin/python3

import os
import tempfile
import shutil
import sys
import subprocess
import traceback
import logging
import re
import threading
import time
import unicodedata

skip_records = [
    "102680",  # bad *019$a
]

current_directory = os.path.dirname(__file__)
lock = threading.RLock()
exit_on_error = False
print_first_error_only = True

config = {}
with open(os.path.join(current_directory, "normarc-to-marc21-test.config")) as f:
    for line in f:
        if line.startswith("#"):
            continue
        key, value = line.split("=", 1)
        config[key.strip()] = value.strip()

target = os.path.join(current_directory, "target")
records = os.path.join(target, "records")

normarc_xslt_path = os.path.join(current_directory, "marcxchange-to-opf.normarc.xsl")
marc21_xslt_path = os.path.join(current_directory, "marcxchange-to-opf.xsl")

already_handled_file = os.path.join(target, "already-handled.txt")
already_handled = []
if os.path.isfile(already_handled_file):
    with open(already_handled_file) as f:
        already_handled = f.readlines()
        already_handled = [line.strip() for line in already_handled]


def mark_as_handled(identifier):
    global lock
    global already_handled_file
    global already_handled
    with lock:
        with open(already_handled_file, "a") as f:
            f.write(identifier + "\n")
        already_handled.append(identifier)


def writefile(outdir, identifier, lines, source_lines):
    assert os.path.isdir(outdir), f"{outdir}"
    assert identifier is not None, f"lines: {lines}"
    header = [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<marcxchange:record format="bibliofilmarc" type="Bibliographic" xmlns:marcxchange="info:lc/xmlns/marcxchange-v1">'
    ]
    footer = [
        '</marcxchange:record>'
    ]
    lines = header + lines + footer
    lines = [line + "\n" for line in lines]  # add newlines
    with open(os.path.join(outdir, f"{identifier}.xml"), "w") as f:
        f.writelines(lines)
    with open(os.path.join(outdir, f"{identifier}.txt"), "w") as f:
        f.writelines(source_lines)


def xslt(stylesheet=None, source=None, target=None, parameters={}, template=None, cwd=None):
    global current_directory

    assert stylesheet
    assert source or template

    if not cwd:
        cwd = current_directory

    success = False
    timeout = 600

    command = ["java", "-jar", config["saxon_jar"]]
    if source:
        command.append("-s:" + source)
    else:
        command.append("-it:" + template)
    command.append("-xsl:" + stylesheet)
    if target:
        command.append("-o:" + target)
    for param in parameters:
        command.append(param + "=" + parameters[param])

    try:
        process = subprocess.run(command,
                                 stdout=subprocess.PIPE,
                                 stderr=subprocess.PIPE,
                                 shell=False,
                                 cwd=cwd,
                                 timeout=timeout,
                                 check=True)

        success = process.returncode == 0
    
    except subprocess.CalledProcessError as process:
        logging.error(process.stdout.decode("utf-8"))
        logging.error(process.stderr.decode("utf-8"))

    except subprocess.TimeoutExpired:
        logging.exception(f"The XSLT timed out: {stylesheet}")

    except Exception:
        logging.exception(f"An error occured while running the XSLT: {stylesheet}")
    
    return success


# https://stackoverflow.com/a/517974/281065
def remove_accents(input_str):
    nfkd_form = unicodedata.normalize('NFKD', input_str)
    return u"".join([c for c in nfkd_form if not unicodedata.combining(c)])


def compare(identifier, normarc_path, marc21_path, normarc_source_path, marc21_source_path, detailed_comparison=False):
    global lock
    global normarc_target_dir
    global marc21_target_dir
    global records
    global print_first_error_only

    with lock:
        normarc = None
        marc21 = None
        normarc_source = None
        marc21_source = None
        with open(normarc_path) as f:
            normarc = f.readlines()
        with open(marc21_path) as f:
            marc21 = f.readlines()
        with open(normarc_source_path) as f:
            normarc_source = f.readlines()
        with open(marc21_source_path) as f:
            marc21_source = f.readlines()
        
        linenum = 0
        normarc_skip_lines = []
        marc21_skip_lines = []

        normarc_has_sortingKey_from_100w_or_245w = False
        normarc_has_490_without_refines = False
        normarc_574a_without_Originaltittel = []
        marc21_has_spaces_in_019a = False
        normarc_has_brackets_in_019a = False  # for instance: only "bu" is extracted from "[b,bu,u]"
        normarc_is_deleted = False
        normarc_has_008 = False
        normarc_marc21_008_pos_33 = []
        for line in normarc:
            if "sortingKey" in line and "*245$w" in line or "*100$w" in line:
                normarc_has_sortingKey_from_100w_or_245w = True
            if '"dc:title.series"' in line and " id=" not in line:
                normarc_has_490_without_refines = True
        for line in normarc_source:
            if "*008" in line:
                normarc_has_008 = True
                if len(line) > 4+33:
                    normarc_marc21_008_pos_33.append(line[4+33])  # *008/33
            if "*000" in line and line[9] == "d":
                normarc_is_deleted = True
            if "*019" in line and "$a" in line:
                value = line.split("$a")[1].split("$")[0]
                if "[" in value or "]" in value:
                    normarc_has_brackets_in_019a = True
            if "*574" in line and "$a" in line:
                a = line.split("$a")[1].split("$")[0]
                if not a.startswith("Originaltittel:") and not a.startswith("Originaltittel :"):
                    normarc_574a_without_Originaltittel.append(f">{a}<")  # adding >< for easier comparison with meta elements
        for line in marc21_source:
            if "*008" in line and len(line) > 4+33:
                normarc_marc21_008_pos_33.append(line[4+33])  # *008/33
            if line.startswith("*019") and "$a" in line and " " in line.split("$a")[1].split("$")[0]:
                marc21_has_spaces_in_019a = True
        
        if normarc_is_deleted:
            if not normarc_has_008:
                print(f"Skipping deleted record with no *008l: {identifier}")
                return True
            if len(normarc_marc21_008_pos_33) != 2 or normarc_marc21_008_pos_33[0] != normarc_marc21_008_pos_33[1]:
                print(f"Skipping deleted record with different *008/33: {identifier}")
                return True
        
        normarc_linenum = -1
        marc21_linenum = -1
        prev_normarc_linenum = -1
        prev_marc21_linenum = -1
        while linenum < len(normarc):
            prev_normarc_linenum = normarc_linenum
            prev_marc21_linenum = marc21_linenum
            normarc_offset = len(normarc_skip_lines)
            marc21_offset = len(marc21_skip_lines)
            normarc_linenum = linenum + normarc_offset
            marc21_linenum = linenum + marc21_offset

            if detailed_comparison and prev_normarc_linenum >= 0 and prev_marc21_linenum >= 0:
                if normarc_linenum == prev_normarc_linenum and marc21_linenum > prev_marc21_linenum:
                    print(f"skipped  MARC21 line {prev_normarc_linenum+1:02}: {marc21[prev_marc21_linenum].strip()}")
                elif normarc_linenum > prev_normarc_linenum and marc21_linenum == prev_marc21_linenum:
                    print(f"skipped NORMARC line {prev_marc21_linenum+1:02}: {normarc[prev_normarc_linenum].strip()}")
                else:
                    print(f"        NORMARC line {prev_normarc_linenum+1:02}: {normarc[prev_normarc_linenum].strip()}")
                    print(f"         MARC21 line {prev_marc21_linenum+1:02}: {marc21[prev_marc21_linenum].strip()}")
                print("---")

            if normarc_linenum > len(normarc) - 1 and marc21_linenum > len(marc21) - 1:
                # done
                break

            if normarc_linenum > len(normarc) - 1 and marc21_linenum <= len(marc21) - 1:
                if not print_first_error_only or not error_has_occured:
                    print("\n".join(normarc_skip_lines))
                    print("\n".join(marc21_skip_lines))
                    print()
                    print("No more lines in NORMARC. Remaining lines in MARC21 are:")
                    print()
                    print("\n".join(normarc[normarc_linenum:]))
                    print()
                return False
            
            if normarc_linenum <= len(normarc) - 1 and marc21_linenum > len(marc21) - 1:
                if not print_first_error_only or not error_has_occured:
                    print("\n".join(normarc_skip_lines))
                    print("\n".join(marc21_skip_lines))
                    print()
                    print("No more lines in MARC21. Remaining lines in NORMARC are:")
                    print()
                    print("\n".join(marc21[marc21_linenum:]))
                    print()
                return False
            
            normarc_line = re.sub(r"  +", " ", normarc[normarc_linenum].strip())
            marc21_line = re.sub(r"  +", " ", marc21[marc21_linenum].strip())

            normarc_line_comment = ""
            marc21_line_comment = ""
            if " <!--" in normarc_line:
                [normarc_line, normarc_line_comment] = normarc_line.split(" <!--", 1)
                normarc_line_comment = "<!--" + normarc_line_comment
            if " <!--" in marc21_line:
                [marc21_line, marc21_line_comment] = marc21_line.split(" <!--", 1)
                marc21_line_comment = "<!--" + marc21_line_comment
            
            # *490$v is set to 1 when there's no *440$v, or copied from *440$v, even when that isn't necessarily correct
            if re.match(r'<meta property="series.position" refines="#series-title-X">\d+</meta>', marc21_line) and "*490$v" in marc21_line_comment:
                marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #1): {marc21_line}")
                continue

            # Handle differences in the authority registry
            normarc_line_property = normarc_line.split('property="')[1].split('"')[0] if "property=" in normarc_line else normarc_line.split("<")[1].split(">")[0].split(" ")[0]
            marc21_line_property = marc21_line.split('property="')[1].split('"')[0] if "property=" in marc21_line else marc21_line.split("<")[1].split(">")[0].split(" ")[0]
            if normarc_line_property in ["sortingKey", "dc:creator"]:
                normarc_line = normarc_line.replace("å", "aa").replace("Å", "Aa")
                normarc_line = normarc_line.replace("-", " ")
                normarc_line = remove_accents(normarc_line)
            if marc21_line_property in ["sortingKey", "dc:creator"]:
                marc21_line = marc21_line.replace("å", "aa").replace("Å", "Aa")
                marc21_line = marc21_line.replace("-", " ")
                marc21_line = remove_accents(marc21_line)

            # The definition of "adult" has changed from 16+ in NORMARC to 18+ in MARC21
            if normarc_line == '<meta property="typicalAgeRange">16-</meta>':
                normarc_line = '<meta property="typicalAgeRange">18-</meta>'

            # ignore id attributes (at least for now)
            normarc_line = re.sub(r' id="[^"]*"', "", normarc_line)
            marc21_line = re.sub(r' id="[^"]*"', "", marc21_line)

            # Nationality in *100$j etc. not converted properly to MARC21 for some reason. Ignore for now
            if '<meta property="nationality" refines=' in normarc_line:
                normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #2): {normarc_line}")
                continue
            
            # Not sure how dewey is converted yet (if at all), ignore dewey in 650 for now
            if "dc:subject.dewey" in normarc_line:
                normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #3): {normarc_line}")
                continue
            if "dc:subject.dewey" in marc21_line:
                marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #4): {marc21_line}")
                continue

            # Not sure how dc:title.part is converted yet (if at all), ignore part titles (from *740) for now
            if "dc:title.part" in normarc_line:
                normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #5): {normarc_line}")
                continue
            if "dc:title.part" in marc21_line:
                marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #6): {marc21_line}")
                continue
            
            # sorting keys that refine the title or contributors seems to have been removed in MARC21
            if "sortingKey" in normarc_line and 'refines="' in normarc_line:
                normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #7): {normarc_line}")
                continue

            # temporary fix in marcxchange-to-opf.normarc.xsl:
            # - *490$v is not converted from NORMARC to MARC21

            # handled in marcxchange-to-opf.normarc.xsl:
            # - *600 are sorted alphabetically in MARC21
            # - *650 are usually sorted alphabetically in MARC21
            # - *700 are sorted alphabetically in MARC21
            # - *610$q is parenthesized and appended to *610$a in MARC21

            # handled in marcxchange-to-opf.xsl:
            # - *650 are sorted alphabetically for easier comparison with NORMARC
            
            # the sorting keys in *100$w and *245$w is not preserved in MARC21
            # so if it is present, we need to ignore the main sortingKey both in NORMARC and in MARC21
            if normarc_has_sortingKey_from_100w_or_245w:
                if "sortingKey" in normarc_line and "refines=" not in normarc_line:
                    normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #8): {normarc_line}")
                    continue
                if "sortingKey" in marc21_line and "refines=" not in marc21_line:
                    marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #9): {marc21_line}")
                    continue
            
            # *490$v is copied from *440$v when there is no *490$v; ignore for now
            if normarc_has_490_without_refines:
                if "series.position" in normarc_line and "refines=" not in normarc_line and "*490" in normarc_line_comment:
                    normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #10): {normarc_line}")
                    continue
                if "series.position" in marc21_line and "refines=" not in marc21_line and "*490" in marc21_line_comment:
                    marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #00): {marc21_line}")
                    continue
            
            if identifier in ["9115", "9275", "9518"]:
                # strange conversion of series metadata, skip for now
                if "*440" in normarc_line_comment or "*490" in normarc_line_comment or "*830" in normarc_line_comment:
                    normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #01): {normarc_line}")
                    continue
                if "*440" in marc21_line_comment or "*490" in marc21_line_comment or "*830" in marc21_line_comment:
                    marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #02): {marc21_line}")
                    continue
            
            if marc21_has_spaces_in_019a or normarc_has_brackets_in_019a:
                # bad conversion of *019$a, skip for now
                if "typicalAgeRange" in normarc_line:
                    normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #03): {normarc_line}")
                    continue
                if "typicalAgeRange" in marc21_line:
                    marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #04): {marc21_line}")
                    continue
            
            # *574$a without "Originaltittel:" prefix is not properly converted to *246$a in MARC21
            if normarc_574a_without_Originaltittel:
                # bad conversion of *574$a, skip for now
                if "*574" in normarc_line_comment:
                    normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #05): {normarc_line}")
                    continue
                if "*500" in marc21_line_comment:
                    for original_title in normarc_574a_without_Originaltittel:
                        if original_title in marc21_line:
                            marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #06): {marc21_line}")
                            break

            # refines attribute names differ when there is both a *440 and a *490 in NORMARC, so just ignore the numbering in those cases
            normarc_line = re.sub(r'(refines="#series-title)-\d+', r'\1-X', normarc_line)
            marc21_line = re.sub(r'(refines="#series-title)-\d+', r'\1-X', marc21_line)

            # IDs in the authority registry have changed in many cases
            if "bibliofil-id" in normarc_line and '*' in normarc_line_comment and normarc_line_comment.split('*')[1].split(' ')[0] in ["100$_", "600$_", "650$_", "653$_", "655$_", "700$_"]:
                normarc_line = re.sub(r'>\d+<', '>X<', normarc_line)
            if "bibliofil-id" in marc21_line and '*' in marc21_line_comment and marc21_line_comment.split('*')[1].split(' ')[0] in ["100$_", "600$_", "650$_", "653$_", "655$_", "700$_"]:
                marc21_line = re.sub(r'>\d+<', '>X<', marc21_line)
            
            if normarc_line != marc21_line:
                if print_first_error_only and not error_has_occured:
                    print("\n".join(normarc_skip_lines))
                    print("\n".join(marc21_skip_lines))
                    print()
                    print("Lines are different:")
                    print()
                    print(f"NORMARC (line {normarc_linenum + 1}): {normarc_line}  {normarc_line_comment}")
                    print(f"MARC21 (line {marc21_linenum + 1}):  {marc21_line}  {marc21_line_comment}")
                    print()
                return False
            
            linenum += 1

        return True


if not os.path.exists(records):
    # marc files:
    # data.vmarc.txt
    # data.aut.txt
    # data.emarc.txt

    # not marc files:
    # data.exemp.txt

    for marcname in ["normarc", "marc21"]:
        for tablename in ["vmarc"]:
            infile = os.path.join(config["source_data"], marcname, f"data.{tablename}.txt")
            outdir = os.path.join(records, marcname, tablename)
            os.makedirs(outdir, exist_ok=True)

            identifier = None
            lines = []
            source_lines = []
            print(f"Processing: {infile}")
            with open(infile) as f:
                for line in f.readlines():
                    if line.startswith("^"):
                        writefile(outdir, identifier, lines, source_lines)
                        identifier = None
                        lines = []
                        source_lines = []
                    elif line.startswith("*00"):
                        tag = line[1:4]
                        data = line.strip()[4:]
                        data = data.replace("<", "&lt;").replace(">", "&gt;").replace("&", "&amp;")
                        lines.append(f'    <marcxchange:controlfield tag="{tag}">{data}</marcxchange:controlfield>')
                    elif line.startswith("*"):
                        tag = line[1:4]
                        ind1 = line[4]
                        ind2 = line[5]
                        subfields = line.strip()[5:].split("$")[1:]
                        lines.append(f'    <marcxchange:datafield tag="{tag}" ind1="{ind1}" ind2="{ind2}">')
                        for subfield in subfields:
                            code = subfield[0]
                            data = subfield[1:]
                            data = data.replace("<", "&lt;").replace(">", "&gt;").replace("&", "&amp;")
                            lines.append(f'        <marcxchange:subfield code="{code}">{data}</marcxchange:subfield>')
                        lines.append(f'    </marcxchange:datafield>')
                    else:
                        assert False, f"Unexpected line: '{line}'"
                    source_lines.append(line)

                    if marcname in ["normarc", "marc21"] and tablename == "vmarc" and line[1:4] == "001":
                        identifier = line.strip()[4:].lstrip("0")


record_files_normarc = set(os.listdir(os.path.join(records, "normarc", "vmarc")))
record_files_marc21 = set(os.listdir(os.path.join(records, "marc21", "vmarc")))
record_files = record_files_normarc.intersection(record_files_marc21)
identifiers = [filename[:-4] for filename in record_files if filename.endswith(".xml")]
identifiers = [str(identifier) for identifier in sorted([int(ident) for ident in identifiers])]

normarc_target_dir = os.path.join(target, "opf", "normarc")
marc21_target_dir = os.path.join(target, "opf", "marc21")
os.makedirs(normarc_target_dir, exist_ok=True)
os.makedirs(marc21_target_dir, exist_ok=True)

successful = len(already_handled)
failed = 0
handled_in_this_run = 0
error_has_occured = False

def handle(identifier, detailed_comparison=False):
    global lock
    global normarc_target_dir
    global marc21_target_dir
    global identifiers
    global successful
    global failed
    global error_has_occured
    global print_first_error_only
    global records
    normarc_file = os.path.join(records, "normarc", "vmarc", f"{identifier}.xml")
    marc21_file = os.path.join(records, "marc21", "vmarc", f"{identifier}.xml")
    normarc_source_file = os.path.join(records, "normarc", "vmarc", f"{identifier}.txt")
    marc21_source_file = os.path.join(records, "marc21", "vmarc", f"{identifier}.txt")

    normarc_opf_file = os.path.join(normarc_target_dir, f"{identifier}.opf")
    marc21_opf_file = os.path.join(marc21_target_dir, f"{identifier}.opf")
    
    success = xslt(normarc_xslt_path, normarc_file, normarc_opf_file, parameters={"include-source-reference-as-comments": "true"})
    assert success, f"Failed to transform: {normarc_file}"
    success = xslt(marc21_xslt_path, marc21_file, marc21_opf_file, parameters={"include-source-reference-as-comments": "true"})
    assert success, f"Failed to transform: {marc21_file}"

    with lock:
        equal = compare(identifier, normarc_opf_file, marc21_opf_file, normarc_source_file, marc21_source_file, detailed_comparison=detailed_comparison)
        
        if not equal:
            if not print_first_error_only or not error_has_occured:
                print(f"{successful} of {len(identifiers)} successful so far ({int(10000 * successful / len(identifiers)) / 100}%)")
                print()
                print(f"{identifier}:")
                print(f"- NORMARC in: {normarc_file}")
                print(f"- MARC21 in: {marc21_file}")
                print(f"- NORMARC OPF out: {normarc_opf_file}")
                print(f"- MARC21 OPF out: {marc21_opf_file}")
                print()
                print("Open all in editor:")
                print(f"{config.get('editor', 'subl')} {normarc_opf_file} {marc21_opf_file} {normarc_file} {marc21_file}")
            error_has_occured = True
            failed += 1
            if (successful + failed) % 10 == 0 or (successful + failed) == len(identifiers):
                print(f"{(successful + failed)} of {len(identifiers)} processed. {successful} ({int(10000 * successful / len(identifiers)) / 100}%) successful and {failed} ({int(10000 * failed / len(identifiers)) / 100}%) failed so far. Last: {identifier})")
            return False
        else:
            mark_as_handled(identifier)
            successful += 1
            if (successful + failed) % 10 == 0 or (successful + failed) == len(identifiers):
                print(f"{(successful + failed)} of {len(identifiers)} processed. {successful} ({int(10000 * successful / len(identifiers)) / 100}%) successful and {failed} ({int(10000 * failed / len(identifiers)) / 100}%) failed so far. Last: {identifier})")
            return True

detailed_comparison = "--detailed-comparison" in sys.argv
for identifier in identifiers:
    if identifier in already_handled:
        continue

    if identifier in skip_records:
        continue

    success = False
    try:
        success = handle(identifier, detailed_comparison=detailed_comparison)
    except Exception as e:
        print(f"An error occured when handling {identifier}: {e}")
        continue
    
    if success:
        handled_in_this_run += 1
    elif exit_on_error:
        sys.exit(1)
    
    if handled_in_this_run >= 3:
        break
    
if handled_in_this_run >= 3:
    print("Processed three records synchronously, now switching to parallel processing")
    thread_pool = []
    for identifier in identifiers:
        if error_has_occured and exit_on_error:
            sys.exit(1)
        if identifier in already_handled:
            continue
        while len(thread_pool) >= 10:
            if error_has_occured and exit_on_error:
                sys.exit(1)
            thread_pool = [t for t in thread_pool if t.is_alive()]
            time.sleep(0.1)
        thread_pool.append(threading.Thread(target=handle, args=(identifier,)))
        thread_pool[-1].start()
    for thread in thread_pool:
        thread.join()
