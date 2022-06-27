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

current_directory = os.path.dirname(__file__)
lock = threading.RLock()

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


def writefile(outdir, identifier, lines):
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


def xslt(stylesheet=None, source=None, target=None, parameters={}, template=None, cwd=None):
    global current_directory

    assert stylesheet
    assert source or template

    if not cwd:
        cwd = current_directory

    success = False
    timeout = 600

    try:
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

        process = subprocess.run(command,
                                            stdout=subprocess.PIPE,
                                            stderr=subprocess.PIPE,
                                            shell=False,
                                            cwd=cwd,
                                            timeout=timeout,
                                            check=True)

        logging.info(process.stdout.decode("utf-8"))
        logging.info(process.stderr.decode("utf-8"))

        success = process.returncode == 0

    except subprocess.TimeoutExpired:
        logging.exception(f"The XSLT timed out: {stylesheet}")

    except Exception:
        logging.exception(f"An error occured while running the XSLT: {stylesheet}")
    
    return success


def compare(identifier, normarc_path, marc21_path):
    global lock
    with lock:
        normarc = None
        marc21 = None
        with open(normarc_path) as f:
            normarc = f.readlines()
        with open(marc21_path) as f:
            marc21 = f.readlines()
        
        linenum = 0
        normarc_offset = 0
        marc21_offset = 0
        while linenum < len(normarc):
            normarc_linenum = linenum + normarc_offset
            marc21_linenum = linenum + marc21_offset

            if normarc_linenum > len(normarc) - 1 and marc21_linenum > len(marc21) - 1:
                # done
                break

            if normarc_linenum > len(normarc) - 1 and marc21_linenum <= len(marc21) - 1:
                print("No more lines in NORMARC. Remaining lines in MARC21 are:")
                print()
                print("\n".join(normarc[normarc_linenum:]))
                print()
                return False
            
            if normarc_linenum <= len(normarc) - 1 and marc21_linenum > len(marc21) - 1:
                print("No more lines in MARC21. Remaining lines in NORMARC are:")
                print()
                print("\n".join(marc21[marc21_linenum:]))
                print()
                return False
            
            normarc_line = re.sub(r"  +", " ", normarc[normarc_linenum].strip())
            marc21_line = re.sub(r"  +", " ", marc21[marc21_linenum].strip())

            # Handle differences in the authority registry
            if "property=" in normarc_line and normarc_line.split('property="')[1].split('"')[0] in ["sortingKey"]:
                normarc_line = normarc_line.replace("å", "aa").replace("Å", "Aa")
                normarc_line = normarc_line.replace("ö", "ø").replace("Ö", "Ø")
                normarc_line = normarc_line.replace("Saint Exupéry, Antoine de", "Saint-Exupéry, Antoine de")
                normarc_line = normarc_line.replace("Lagerkvist, Pær", "Lagerkvist, Pär")
            if "property=" in marc21_line and marc21_line.split('property="')[1].split('"')[0] in ["sortingKey"]:
                marc21_line = marc21_line.replace("å", "aa").replace("Å", "Aa")
                marc21_line = marc21_line.replace("ö", "ø").replace("Ö", "Ø")

            # The definition of "adult" has changed from 17+ in NORMARC to 18+ in MARC21
            if normarc_line == '<meta property="typicalAgeRange">17-</meta>':
                normarc_line = '<meta property="typicalAgeRange">18-</meta>'
            
            # Age ranges work differently in MARC21
            # NORMARC=MARC21: a=aa,a | b≈b | bu≈bu | u=u | mu≈mu,vu
            if "typicalAgeRange" in normarc_line:
                # 13-16 is now 13-15, and 17+ is now 18+ (adults are now 18+ instead of 17+)
                normarc_line = normarc_line.replace("-16<", "-15<")
                normarc_line = normarc_line.replace(">17-", ">18-")

                # 7/8 is now 8/9
                normarc_line = normarc_line.replace("-7<", "-8<")
                normarc_line = normarc_line.replace(">8-", ">9-")

            # ignore id attributes (at least for now)
            normarc_line = re.sub(r' id="[^"]*"', "", normarc_line)
            marc21_line = re.sub(r' id="[^"]*"', "", marc21_line)

            # Nationality in *100$j etc. not converted properly to MARC21 for some reason. Ignore for now
            if '<meta property="nationality" refines=' in normarc_line:
                normarc_offset += 1
                continue
            
            # Not sure how dewey is converted yet (if at all), ignore dewey in 650 for now
            if "dc:subject.dewey" in normarc_line:
                normarc_offset += 1
                continue
            if "dc:subject.dewey" in marc21_line:
                marc21_offset += 1
                continue

            # Not sure how dc:title.part is converted yet (if at all), ignore part titles (from *740) for now
            if "dc:title.part" in normarc_line:
                normarc_offset += 1
                continue
            if "dc:title.part" in marc21_line:
                marc21_offset += 1
                continue
            
            # sorting keys that refine the title or contributors seems to have been removed in MARC21
            if "sortingKey" in normarc_line and 'refines="' in normarc_line:
                normarc_offset += 1
                continue
            
            if normarc_line != marc21_line:
                print("Lines are different:")
                print()
                print(f"NORMARC (line {normarc_linenum}): {normarc_line.strip()}")
                print(f"MARC21 (line {marc21_linenum}):  {marc21_line.strip()}")
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
            print(f"Processing: {infile}")
            with open(infile) as f:
                for line in f.readlines():
                    if line.startswith("^"):
                        writefile(outdir, identifier, lines)
                        identifier = None
                        lines = []
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
handled_in_this_run = 0
error_has_occured = False

def handle(identifier):
    global lock
    global normarc_target_dir
    global marc21_target_dir
    global identifiers
    global successful
    global error_has_occured
    global records
    normarc_file = os.path.join(records, "normarc", "vmarc", f"{identifier}.xml")
    marc21_file = os.path.join(records, "marc21", "vmarc", f"{identifier}.xml")

    normarc_opf_file = os.path.join(normarc_target_dir, f"{identifier}.opf")
    marc21_opf_file = os.path.join(marc21_target_dir, f"{identifier}.opf")
    
    success = xslt(normarc_xslt_path, normarc_file, normarc_opf_file)
    assert success, f"Failed to transform: {normarc_file}"
    success = xslt(marc21_xslt_path, marc21_file, marc21_opf_file)
    assert success, f"Failed to transform: {marc21_file}"

    with lock:
        equal = compare(identifier, normarc_opf_file, marc21_opf_file)
        
        if not equal:
            print(f"{successful} of {len(identifiers)} successful so far ({int(10000 * successful / len(identifiers)) / 100}%)")
            print()
            print(f"{identifier}:")
            print(f"- NORMARC in: {normarc_file}")
            print(f"- MARC21 in: {marc21_file}")
            print(f"- NORMARC OPF out: {normarc_opf_file}")
            print(f"- MARC21 OPF out: {marc21_opf_file}")
            error_has_occured = True
            return False
        else:
            mark_as_handled(identifier)
            successful += 1
            if successful % 10 == 0 or successful == len(identifiers):
                print(f"{successful} of {len(identifiers)} successful so far ({int(10000 * successful / len(identifiers)) / 100}%, last: {identifier})")
            return True

for identifier in identifiers:
    if identifier in already_handled:
        continue

    success = handle(identifier)
    if success:
        handled_in_this_run += 1
    else:
        sys.exit(1)
    
    if handled_in_this_run >= 3:
        break
    
if handled_in_this_run >= 3:
    print("3 successful in a row, switching to parallel processing")
    thread_pool = []
    for identifier in identifiers:
        if error_has_occured:
            sys.exit(1)
        if identifier in already_handled:
            continue
        while len(thread_pool) >= 10:
            if error_has_occured:
                sys.exit(1)
            thread_pool = [t for t in thread_pool if t.is_alive()]
            time.sleep(0.1)
        thread_pool.append(threading.Thread(target=handle, args=(identifier,)))
        thread_pool[-1].start()
    for thread in thread_pool:
        thread.join()
