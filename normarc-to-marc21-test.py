#!/usr/bin/python3

import os
import tempfile
import shutil
import sys
import subprocess
import traceback
import logging
import re

current_directory = os.path.dirname(__file__)

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
    global already_handled_file
    global already_handled
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
        
        normarc_line = normarc[normarc_linenum].strip()
        marc21_line = marc21[marc21_linenum].strip()

        # Nationality in *100$j etc. not converted properly to MARC21 for some reason. Ignore for now
        if '<meta property="nationality" refines=' in normarc_line:
            normarc_offset += 1
            continue
        
        # Not sure how dewey is converted yet (if at all), ignore dewey in 650 for now
        if "dc:subject.dewey" in normarc_line:
            normarc_offset += 1
            continue
        if 'id="subject-650' in normarc_line:
            normarc_line = re.sub(r' id="[^"]*"', "", normarc_line)
        if "dc:subject.dewey" in marc21_line:
            marc21_offset += 1
            continue
        if 'id="subject-650' in marc21_line:
            marc21_line = re.sub(r' id="[^"]*"', "", marc21_line)
        
        if normarc_line != marc21_line:
            print("Lines are different:")
            print()
            print(f"NORMARC: {normarc_line.strip()}")
            print(f"MARC21:  {marc21_line.strip()}")
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
            os.makedirs(outdirexist_ok=True)

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
for identifier in identifiers:
    if identifier in already_handled:
        continue
    
    normarc_file = os.path.join(records, "normarc", "vmarc", f"{identifier}.xml")
    marc21_file = os.path.join(records, "marc21", "vmarc", f"{identifier}.xml")

    normarc_opf_file = os.path.join(normarc_target_dir, f"{identifier}.opf")
    marc21_opf_file = os.path.join(marc21_target_dir, f"{identifier}.opf")
    
    success = xslt(normarc_xslt_path, normarc_file, normarc_opf_file)
    assert success, f"Failed to transform: {normarc_file}"
    success = xslt(marc21_xslt_path, marc21_file, marc21_opf_file)
    assert success, f"Failed to transform: {marc21_file}"

    equal = compare(identifier, normarc_opf_file, marc21_opf_file)
    
    if not equal:
        print(f"{successful} of {len(identifiers)} successful so far")
        print()
        print(f"{identifier}:")
        print(f"- NORMARC in: {normarc_file}")
        print(f"- MARC21 in: {marc21_file}")
        print(f"- NORMARC OPF out: {normarc_opf_file}")
        print(f"- MARC21 OPF out: {marc21_opf_file}")
        sys.exit(1)
    else:
        mark_as_handled(identifier)
        successful += 1
