#!/usr/bin/python3

import os
import tempfile
import shutil
import sys

# hardcode in for now, move to config in the future if necessary
source_data = "/home/jostein/Dokumenter/2022/BS-MARC21/dumpreg"

target = os.path.join(os.path.dirname(__file__), "target")
records = os.path.join(target, "records")


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


def xslt(xslt, xml):
    global target
    # TODO
    # return filename


def compare(normarc, marc21):
    # TODO: assertions here
    sys.exit(1)


if not os.path.exists(records):
    # marc files:
    # data.vmarc.txt
    # data.aut.txt
    # data.emarc.txt

    # not marc files:
    # data.exemp.txt

    for marcname in ["normarc", "marc21"]:
        for tablename in ["vmarc"]:
            infile = os.path.join(source_data, marcname, f"data.{tablename}.txt")
            outdir = os.path.join(records, marcname, tablename)
            os.makedirs(outdir)

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

for identifier in identifiers:
    print("Comparing:")
    normarc_file = os.path.join(records, "normarc", "vmarc", f"{identifier}.xml")
    marc21_file = os.path.join(records, "marc21", "vmarc", f"{identifier}.xml")
    print(f"- NORMARC: {normarc_file}")
    print(f"- MARC21: {marc21_file}")

    normarc_opf_file = xslt("marcxchange-to-opf.normarc.xsl", normarc_file)
    marc21_opf_file = xslt("marcxchange-to-opf.xsl", marc21_file)
    compare(normarc_opf_file, marc21_opf_file)

    sys.exit(1)



# 1. sett inn:
# <?xml version="1.0" encoding="utf-8"?>
# <marcxchange:record format="bibliofilmarc" type="Bibliographic" xmlns:marcxchange="info:lc/xmlns/marcxchange-v1">
# 
# 2. for *000-*009, pakk inn i:
# <marcxchange:controlfield tag="00…">…</marcxchange:controlfield>
# 
# 3. for *010-*999:
# <marcxchange:datafield tag="…" ind1="…" ind2="…">
#     <marcxchange:subfield code="…">…</marcxchange:subfield>
#     <marcxchange:subfield code="…">…</marcxchange:subfield>
# </marcxchange:datafield>
# 
# 4. for ^ eller EOF:
# </marcxchange:record>
