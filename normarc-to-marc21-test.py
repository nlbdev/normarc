#!/usr/bin/python3

import os
import sys
import subprocess
import logging
import re
import threading
import time
import unicodedata

skip_records = [
    # bad *019$a
#    "102680",

    # *019$d is moved to *019$b by mistake
#    "106789", "383239", "683239",
    
    # multiple *019
#    "182386", "582386", "613963",
    
    # missing *019$b
#    "123415", "280321", "551045", "552567", "552601", "552992", "555642", "557591", "558240", "559663",
#    "560234", "560875", "561456", "566458", "581504", "581519", "627342", "850084", "900090", "900096",
    
    # two *019$b
#    "115495", "120201", "120202", "120203", "120204", "120205", "120206", "120207", "120208", "120209",
#    "120210", "120211", "120212", "120213", "120214", "120215", "120216", "120217", "120218", "120219",
#    "120220", "371261", "372540", "372544", "372555", "373587", "373607", "373634", "373644", "380001",
#    "380002", "380004", "380005", "380006", "380011", "380014", "380015", "380018", "380019", "380028",
#    "380033", "380035", "380037", "380038", "380042", "380044", "380046", "380047", "380048", "380049",
#    "380050", "380052", "380059", "380061", "380062", "380065", "380066", "380068", "380069", "380070",
#    "380071", "380074", "380076", "380077", "380078", "380079", "380080", "380081", "380082", "380083",
#    "380084", "380085", "380086", "380088", "380089", "380090", "380091", "380092", "380096", "380097",
#    "380099", "380100", "380101", "380102", "380103", "380104", "380107", "380108", "380109", "380110",
#    "380111", "380112", "380113", "380114", "380115", "380116", "380117", "380119", "380123", "380124",
#    "380125", "380126", "380129", "380130", "380131", "380132", "380133", "380134", "380135", "380136",
#    "380137", "380138", "380139", "380140", "380142", "380143", "380144", "380145", "380146", "380147",
#    "380148", "380149", "380150", "380151", "380152", "380154", "380156", "380157", "380159", "380160",
#    "380161", "380162", "380164", "380166", "380341", "381170", "381172", "381176", "381188", "381446",
#    "554157", "558276", "558278", "558280", "558281", "558282", "558284", "558285", "558286", "558287",
#    "558288", "558289", "558290", "558291", "558292", "558293", "558294", "558295", "559982", "560565",
#    "561982", "561983", "561984", "564789", "565950", "566080", "580162", "581572", "582689", "582774",
#    "583553", "611823", "612045", "613748", "618360", "618363", "618720", "624576", "624578", "624580",
#    "624581", "624582", "624584", "624585", "624586", "624587", "624588", "624589", "624590", "624591",
#    "624592", "624593", "624594", "624595", "626282", "626865", "628282", "628283", "628284", "630045",
#    "632635", "681572", "682689", "682690", "682774", "683553", "849950", "849951", "849952", "849953",
#    "849954", "849955", "849956", "849957", "849958", "849959", "849960", "849961", "849962", "849963",
#    "849964", "849966", "849967", "849968", "849969", "849970", "849971", "849972", "849973", "849974",
#    "849975", "849976", "849977", "849978", "849979", "849980", "849981", "849982", "849983", "849984",
#    "849985", "849986", "849987", "849988", "849989", "849990", "849991", "849992", "849993", "849994",
#    "849995", "849996", "849997", "849998", "849999", "852355", "857816", "857818", "857823", "857824",
#    "857825", "857833", "857847", "857853", "857860", "857861", "857866", "857867", "857905", "857918",
#    "857921", "861144", "861145", "861150", "862185", "862195", "862205", "900023",
    
    # In these records", "*100$j are not converted from Normarc to Marc 21:
#    "107158", "107620", "108950", "109773", "111525", "112386", "112427", "117506", "121884", "123453",
#    "124225", "124950", "180155", "180158", "180378", "181374", "183972", "183973", "183979", "183984",
#    "183986", "183990", "184005", "184006", "184009", "184010", "184011", "184018", "184025", "184026",
#    "184027", "184028", "184054", "184055", "184057", "184062", "184067", "184068", "184070", "184075",
#    "184079", "184080", "184081", "184082", "184083", "184084", "184086", "185055", "220702", "223578",
#    "229350", "280149", "282438", "283941", "283989", "283993", "284002", "284012", "284029", "284034",
#    "284036", "284040", "284041", "284045", "284048", "284059", "284072", "284076", "361257", "361260",
#    "370814", "371294", "372679", "373701", "373764", "373778", "375440", "375444", "375680", "376053",
#    "380149", "381374", "382438", "383941", "383972", "383979", "383984", "383986", "383987", "383989",
#    "383990", "383993", "384002", "384005", "384006", "384009", "384010", "384011", "384012", "384018",
#    "384022", "384029", "384034", "384036", "384040", "384041", "384045", "384048", "384054", "384055",
#    "384056", "384057", "384059", "384062", "384067", "384068", "384070", "384072", "384075", "384076",
#    "384079", "384080", "384081", "384082", "384083", "384084", "394080", "524225", "550854", "551750",
#    "552573", "554325", "555186", "555227", "557502", "560378", "564684", "566150", "580149", "580155",
#    "580158", "580378", "580412", "581374", "582438", "583972", "583973", "583979", "583984", "583986",
#    "583987", "583989", "583990", "583993", "584002", "584005", "584006", "584009", "584010", "584011",
#    "584012", "584018", "584022", "584025", "584026", "584028", "584029", "584034", "584036", "584040",
#    "584041", "584045", "584048", "584054", "584055", "584056", "584057", "584059", "584062", "584067",
#    "584068", "584070", "584072", "584075", "584076", "584079", "584080", "584081", "584082", "584083",
#    "584084", "584086", "604068", "605679", "606934", "607275", "608343", "612673", "613800", "614445",
#    "616162", "616379", "616380", "616381", "616555", "616970", "618050", "618671", "620625", "621486",
#    "627102", "630716", "630984", "680155", "680158", "680412", "681374", "683972", "683973", "683979",
#    "683983", "683984", "683986", "683987", "683990", "683996", "684005", "684006", "684009", "684010",
#    "684011", "684018", "684022", "684049", "684050", "684051", "684052", "684054", "684055", "684056",
#    "684057", "684067", "684068", "684075", "684079", "684080", "684081", "684082", "684083", "684084",
#    "803999", "804001",
    
    # *245$a gets a trailing " ="
    #"104518", "104539", "106040", "106494", "116583", "1757", "202191", "204531", "208801", "209448",
    #"210485", "213772", "223879", "280156", "282998", "302315", "302344", "302369", "302387", "302388",
    #"302389", "302394", "361878", "371346", "372453", "380156", "382059", "382998", "400020", "559383",
    #"560679", "580156", "582059", "582998", "601757", "610424", "610846", "612493", "625559", "625683",
    #"682920", "683084", "857658", "857659", "900044",

    # *245$b gets a trailing " = (…)"
#    "202244",

    # *240$a gets a trailing " :"
#    "209240", "209241",

    # *650$z converted to *650$x by mistake
#    "180806",

    # *785 lost in conversion
#    "181248",

    # duplicate *019 lost in conversion
#    "182386",
]

current_directory = os.path.dirname(__file__)
lock = threading.RLock()
exit_on_error = True
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
        logging.error(" ".join(command))
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
        with open(normarc_source_path) as f:
            normarc_source = f.readlines()
            if "*000" in normarc_source[1] and normarc_source[1][9] == "d":
                print(f"Skipping deleted record: {identifier}")
                return True
        with open(marc21_source_path) as f:
            marc21_source = f.readlines()
        with open(normarc_path) as f:
            normarc = f.readlines()
        with open(marc21_path) as f:
            marc21 = f.readlines()
        
        linenum = 0
        normarc_skip_lines = []
        marc21_skip_lines = []

        normarc_has_sortingKey_from_100w_110w_or_245w = False
        normarc_has_490_without_position = False
        normarc_574a_without_Originaltittel = []
        normarc_has_Originaltittel_in_572a = False
        marc21_has_spaces_in_019a = False
        normarc_has_unknown_values_in_019a = False
        normarc_is_deleted = False
        normarc_has_008 = False
        normarc_marc21_008_pos_33 = []
        normarc_available_during_conversion = False
        normarc_has_authority_with_multiple_nationalities = False
        normarc_dewey_without_refines = []
        for line in normarc:
            if "dc:subject.dewey" in line and "refines" not in line:
                normarc_dewey_without_refines.append(line.split("</meta")[0].split(">")[1])
            if "sortingKey" in line and "*245$w" in line or "*100$w" in line or "*110$w" in line:
                normarc_has_sortingKey_from_100w_110w_or_245w = True
            if "dc:date.available" in line and re.match(r"2022-(1|0[3-9])", line):
                normarc_available_during_conversion = True
        for line in normarc_source:
            if "*008" in line:
                normarc_has_008 = True
                if len(line) > 4+33:
                    normarc_marc21_008_pos_33.append(line[4+33])  # *008/33
            if "*000" in line and line[9] == "d":
                normarc_is_deleted = True
            if "*019" in line and "$a" in line:
                value = line.split("$a")[1].split("$")[0]
                values = value.split(",")
                for value in values:
                    if value not in ["aa", "a", "b", "bu", "u", "mu"]:
                        normarc_has_unknown_values_in_019a = True
            if '*490' in line and "$v" not in line and not re.match(r".*\$a[^$]*;.*", line):
                normarc_has_490_without_position = True
            if "*574" in line and "$a" in line:
                a = line.split("$a")[1].split("$")[0]
                if not a.startswith("Originaltittel:") and not a.startswith("Originaltittel :"):
                    normarc_574a_without_Originaltittel.append(f">{a}<")  # adding >< for easier comparison with meta elements
            if "*572" in line and re.match(r".*\$a\s*Ori?gi(na|an)l(ens )?tit\w*\s*:?\s*.*", line):
                normarc_has_Originaltittel_in_572a = True
            if len(line.split("$j")) > 2:
                normarc_has_authority_with_multiple_nationalities = True
        for line in marc21_source:
            if "*008" in line and len(line) > 4+33:
                normarc_marc21_008_pos_33.append(line[4+33])  # *008/33
            if line.startswith("*019") and "$a" in line and " " in line.split("$a")[1].split("$")[0]:
                marc21_has_spaces_in_019a = True
        
        if normarc_is_deleted:
            if not normarc_has_008:
                print(f"Skipping deleted record with no *008: {identifier}")
                return True
            if len(normarc_marc21_008_pos_33) != 2 or normarc_marc21_008_pos_33[0] != normarc_marc21_008_pos_33[1]:
                print(f"Skipping deleted record with different *008/33: {identifier}")
                return True

        if normarc_available_during_conversion:
            print(f"Skipping record that were made available during conversion from NORMARC to MARC21: {identifier}")
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
            
            # """
            # 
            # # *490$v is set to 1 when there's no *440$v, or copied from *440$v, even when that isn't necessarily correct
            # if re.match(r'<meta property="series.position" refines="#series-title-X">\d+</meta>', marc21_line) and "*490$v" in marc21_line_comment:
            #     marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #1): {marc21_line}")
            #     continue
            # 
            # """
            # 
            
            normarc_line_property = normarc_line.split('property="')[1].split('"')[0] if "property=" in normarc_line else normarc_line.split("<")[1].split(">")[0].split(" ")[0]
            marc21_line_property = marc21_line.split('property="')[1].split('"')[0] if "property=" in marc21_line else marc21_line.split("<")[1].split(">")[0].split(" ")[0]
            
            # Ignore difference in inverted form of name in sortingKey
            if normarc_line_property == "sortingKey":
                normarc_line = re.sub(r">([^<,]*?) *, *([^<]*?)<", r">\2 \1<", normarc_line)
            if marc21_line_property == "sortingKey":
                marc21_line = re.sub(r">([^<,]*?) *, *([^<]*?)<", r">\2 \1<", marc21_line)
            
            # Handle differences in the authority registry
            if normarc_line_property in ["sortingKey", "dc:creator", "dc:subject", "dc:subject.keyword"]:
                normarc_line = normarc_line.replace("Karl Friedrich Hieronymus Mynchhausen", "Karl Friedrich Hieronymus Munchhausen")
                normarc_line = normarc_line.replace("Gunilla Bergstrøm", "Gunilla Bergstrom")
                normarc_line = normarc_line.replace("Anne Cath. Vestly", "Anne-Cath. Vestly")
                normarc_line = normarc_line.replace("Verdenskrigen 1939-1945", "Verdenskrigen")
                normarc_line = normarc_line.replace("Kommunenes sentralforbund(KS)", "Kommunenes sentralforbund")
                normarc_line = normarc_line.replace("Den Norske kirke", "Norske kirke")
                normarc_line = normarc_line.replace("Alexander L. Kielland(oljeplattform)", "Alexander L. Kielland (oljeplattform)")
                normarc_line = normarc_line.replace("å", "aa").replace("Å", "Aa")
                normarc_line = normarc_line.replace("Ð", "D")
                normarc_line = normarc_line.replace("ð", "d")
                normarc_line = normarc_line.replace("-", " ")
                normarc_line = remove_accents(normarc_line)
            if marc21_line_property in ["sortingKey", "dc:creator", "dc:subject", "dc:subject.keyword"]:
                marc21_line = marc21_line.replace("Karl Friedrich Hieronymus Mynchhausen", "Karl Friedrich Hieronymus Munchhausen")
                marc21_line = marc21_line.replace("Gunilla Bergstrøm", "Gunilla Bergstrom")
                marc21_line = marc21_line.replace("Anne Cath. Vestly", "Anne-Cath. Vestly")
                marc21_line = marc21_line.replace("Verdenskrigen 1939-1945", "Verdenskrigen")
                marc21_line = marc21_line.replace("Kommunenes sentralforbund(KS)", "Kommunenes sentralforbund")
                marc21_line = marc21_line.replace("Den Norske kirke", "Norske kirke")
                marc21_line = marc21_line.replace("Alexander L. Kielland(oljeplattform)", "Alexander L. Kielland (oljeplattform)")
                marc21_line = marc21_line.replace("å", "aa").replace("Å", "Aa")
                marc21_line = marc21_line.replace("Ð", "D")
                marc21_line = marc21_line.replace("ð", "d")
                marc21_line = marc21_line.replace("-", " ")
                marc21_line = remove_accents(marc21_line)
            
            # The definition of "adult" has changed from 16+ in NORMARC to 18+ in MARC21
            if normarc_line == '<meta property="typicalAgeRange">16-</meta>':
                normarc_line = '<meta property="typicalAgeRange">18-</meta>'
            
            # if "*" in normarc_line_comment and normarc_line_comment.split("*")[1][:3] in ["600", "650"]:
            #     normarc_line = normarc_line.lower()
            # if "*" in marc21_line_comment and marc21_line_comment.split("*")[1][:3] in ["600", "650"]:
            #     marc21_line = marc21_line.lower()
            # 
            # # for titles, ignore whitespace differences surrounding semicolon
            # if "dc:title" in normarc_line_property:
            #     normarc_line = re.sub(r" *; *", r" ; ", normarc_line)
            # if "dc:title" in marc21_line_property:
            #     marc21_line = re.sub(r" *; *", r" ; ", marc21_line)
            # 
            # # ignore id attributes (at least for now)
            # normarc_line = re.sub(r' id="[^"]*"', "", normarc_line)
            # marc21_line = re.sub(r' id="[^"]*"', "", marc21_line)
            
            # ignore numbering of *700 id- and refines-attributes
            normarc_line = re.sub(r"contributor-700-\d+", "contributor-700-X", normarc_line)
            marc21_line = re.sub(r"contributor-700-\d+", "contributor-700-X", marc21_line)
            
            # sorting keys that refine the title or contributors have been removed in MARC21
            if "sortingKey" in normarc_line and 'refines="' in normarc_line:
                normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #7): {normarc_line}")
                continue
            
            # # *653$q are not copied to MARC21
            # if "*653$q" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #8): {normarc_line}")
            #     continue
            # 
            # # *650$w are not copied to MARC21
            # if "*650$w" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #9): {normarc_line}")
            #     continue
            # 
            # # the sorting keys in *100$w, *110$w and *245$w is not preserved in MARC21
            # # so if it is present, we need to ignore the main sortingKey both in NORMARC and in MARC21
            # if normarc_has_sortingKey_from_100w_110w_or_245w:
            #     if "sortingKey" in normarc_line and "refines=" not in normarc_line:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #10): {normarc_line}")
            #         continue
            #     if "sortingKey" in marc21_line and "refines=" not in marc21_line:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #11): {marc21_line}")
            #         continue
            # 
            # # *490$v is copied from *440$v when there is no *490$v; ignore for now
            # if normarc_has_490_without_position:
            #     if "series.position" in normarc_line and re.match(r".*\*(440|490|830).*", normarc_line_comment):
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #12): {normarc_line}")
            #         continue
            #     if "series.position" in marc21_line and re.match(r".*\*(440|490|830).*", marc21_line_comment):
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #13): {marc21_line}")
            #         continue
            # 
            # """
            # 
            # if identifier in ["9115", "9275", "9518"]:
            #     # strange conversion of series metadata, skip for now
            #     if "*440" in normarc_line_comment or "*490" in normarc_line_comment or "*830" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #14): {normarc_line}")
            #         continue
            #     if "*440" in marc21_line_comment or "*490" in marc21_line_comment or "*830" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #15): {marc21_line}")
            #         continue
            # """
            # 
            # if marc21_has_spaces_in_019a or normarc_has_unknown_values_in_019a:
            #     # bad conversion of *019$a, skip for now
            #     if '"typicalAgeRange"' in normarc_line or '"audience"' in normarc_line:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #16): {normarc_line}")
            #         continue
            #     if '"typicalAgeRange"' in marc21_line or '"audience"' in marc21_line:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #17): {marc21_line}")
            #         continue
            # 
            # # *574$a without "Originaltittel:" prefix is not properly converted to *246$a in MARC21
            # if normarc_574a_without_Originaltittel    :# or normarc_has_Originaltittel_in_572a:
            #     # bad conversion of *574$a or *572$a; skip for now
            #     if "*574" in normarc_line_comment    :#or "*572" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #18): {normarc_line}")
            #         continue
            #     if "*500" in marc21_line_comment:
            #         for original_title in normarc_574a_without_Originaltittel:
            #             if original_title in marc21_line:
            #                 marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #19): {marc21_line}")
            #                 break
            #     if "*246" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #20): {marc21_line}")
            #         break
            # 
            # """
            # 
            # # skip checking the number of pages and volumes for the braille newsletter
            # if identifier in ["120209"]:
            #     if "*300" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #21): {marc21_line}")
            #         continue
            #     if "*300" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #22): {normarc_line}")
            #         continue
            # 
            # # dc:title.original.alternative is not always present in MARC21, and not really important, so we ignore it
            # if normarc_line_property == "dc:title.original.alternative":
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #23): {normarc_line}")
            #     continue
            # if marc21_line_property == "dc:title.original.alternative":
            #     marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #24): {marc21_line}")
            #     continue
            # 
            # # *596$e is not always preserved after conversion to MARC21
            # if "*596$e" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #25): {normarc_line}")
            #     continue
            # if "*596$e" in marc21_line_comment:
            #     marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #25): {marc21_line}")
            #     continue
            # 
            # """
            # 
            # # Actually, let's just ignore all series.position from *440, *490 and *830; there's a lot of problems in its conversion
            # # For instance in 200260, where $v is copied from another datafield
            # if normarc_line_property == "series.position":
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #26): {normarc_line}")
            #     continue
            # if marc21_line_property == "series.position":
            #     marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #27): {marc21_line}")
            #     continue
            # 
            # # multiple *245$a
            # if identifier in ["228728", "373628", "565528"]:
            #     if "245$a" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #28): {normarc_line}")
            #         continue
            #     if "245$a" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #28): {marc21_line}")
            #         continue
            # 
            # # it looks like *246$a is appended to *245$b for some reason, but I'm not sure. Let's ignore it for now
            # if identifier in ["104518"]:
            #     if "*245$b" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #29): {normarc_line}")
            #         continue
            #     if "*245$b" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #30): {marc21_line}")
            #         continue
            # 
            # """
            # # series.issn from *490$x is not included in MARC21
            # if "*490$x" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #31): {normarc_line}")
            #     continue
            # 
            # # refines attribute names differ when there is both a *440 and a *490 in NORMARC, so just ignore the numbering in those cases
            # normarc_line = re.sub(r'(refines="#series-title)-\d+', r'\1-X', normarc_line)
            # marc21_line = re.sub(r'(refines="#series-title)-\d+', r'\1-X', marc21_line)
            # 
            # """
            # 
            # # authorities with multiple nationalities are not properly converted to MARC21
            # if normarc_has_authority_with_multiple_nationalities:
            #     if normarc_line_property == "nationality":
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #32): {normarc_line}")
            #         continue
            #     if marc21_line_property == "nationality":
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #33): {marc21_line}")
            #         continue
            # 
            # # Ignore *700$d for now, as it is not always preserved in MARC21
            # if "*700$d" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #34): {normarc_line}")
            #     continue
            # if "*700$d" in marc21_line_comment:
            #     marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #35): {marc21_line}")
            #     continue
            
            # IDs in the authority registry have changed in many cases, replace them with placeholders
            if "bibliofil-id" in normarc_line:
                normarc_line = re.sub(r">\d+</meta>", ">(…)</meta>", normarc_line)
            if "bibliofil-id" in marc21_line:
                marc21_line = re.sub(r">\d+</meta>", ">(…)</meta>", marc21_line)
            
            # Dewey with refines is not converted to MARC21
            if normarc_line_property == "dc:subject.dewey" and "refines" in normarc_line:
                dewey = normarc_line.split("</meta")[0].split(">")[1]
                if dewey in normarc_dewey_without_refines:
                    normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #38): {normarc_line}")
                    continue
            
            # Dewey in *653$1 is not converted to MARC21 (example: 100833)
            if normarc_line_property == "dc:subject.dewey" and "*653$1" in normarc_line_comment:
                normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #38.2): {normarc_line}")
                continue
            
            # # Nationality in *800$j is not converted to MARC21
            # if "*800$j" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #39): {normarc_line}")
            #     continue
            # 
            # # Part title *740$a is not converted to MARC21
            # if "*740$a" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #40): {normarc_line}")
            #     continue
            # 
            # if identifier in ["181450"]:
            #     # record has change since conversion, ignore for now
            #     if "*240$a" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #41): {normarc_line}")
            #         continue
            # 
            # if identifier in ["104518", "104539", "202191", "202244", "209864", "210485", "212559", "213453", "213772", "218103",
            #                   "223879", "225747", "228024", "228751", "229874", "280048", "280473", "281063", "283629", "283635",
            #                   "283647", "359216", "361878", "363424", "371346", "371684", "372323", "372453", "372514", "380048",
            #                   "380247", "381063", "383393", "560679", "580048", "580048", "580247", "682920", "683084", "683393",
            #                   "900044"]:
            #     # Ignore conversion of parallel title. It looks correct in Marc 21, but it's not clear how it was converted.
            #     if "*245" in normarc_line_comment or "*246" in normarc_line_comment or "*574" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #42): {normarc_line}")
            #         continue
            #     if "*245" in marc21_line_comment or "*246" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #43): {marc21_line}")
            #         continue
            # 
            # if identifier in ["181450", "213312", "381450", "581450"]:
            #     # Problem with conversion of original title, should be fixed in next conversion
            #     if "*574" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #44): {normarc_line}")
            #         continue
            #     if "*246" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #45): {marc21_line}")
            #         continue
            # 
            # if identifier in ["228728"]:
            #     # Problem with conversion of title (multiple $a), should be fixed before next conversion
            #     if "*245$a" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #46): {normarc_line}")
            #         continue
            #     if "*245$a" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #47): {marc21_line}")
            #         continue
            # 
            # if identifier in ["300377", "300553", "300554", "300555", "301281"]:
            #     # Problem with conversion of title (multiple $b), should be fixed before next conversion
            #     if "*245$b" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #47): {normarc_line}")
            #         continue
            #     if "*245$b" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #48): {marc21_line}")
            #         continue
            # 
            # # ISSN in *490$x is not described in Normarc, and not converted to Marc 21. Ignore for now
            # if "*490$x" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #49): {normarc_line}")
            #     continue
            # 
            # # Not sure what happens here when converting *240 to *246, but the result seems fine, so let's ignore it for now
            # if identifier in ["283521"]:
            #     if "*240" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #50): {normarc_line}")
            #         continue
            #     if "*246" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #51): {marc21_line}")
            #         continue
            # 
            # # Instrument in *048$a not converted to Marc 21 yet, ignore for now
            # if "*048$a" in normarc_line_comment:
            #     normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #52): {normarc_line}")
            #     continue
            # 
            # # There are multiple *082 in Normarc, but only one in Marc 21. Ignore for now
            # if identifier in ["300163"]:
            #     if "*082" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #53): {normarc_line}")
            #         continue
            #     if "*082" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #54): {marc21_line}")
            #         continue
            # 
            # # Bad *082 in Normarc, ignore for now
            # if identifier in ["300292", "301763"]:
            #     if "*041$h" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #55): {normarc_line}")
            #         continue
            #     if "*041$h" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #56): {marc21_line}")
            #         continue
            # 
            # # wrong values for *082$z causes problems in conversion, ignore for now
            # if identifier in ["212113", "214374", "221528", "283635", "300163", "300350", "300651", "300653", "300654", "300656",
            #                   "300662", "300740", "300741", "370971", "607116", "613137", "613145", "622164"]:
            #     if "*082" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #57): {normarc_line}")
            #         continue
            #     if "*082" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #58): {marc21_line}")
            #         continue
            #     
            # # the conversion does not seem to handle multiple *650$q subfields correctly
            # if identifier in ["372757", "621154", "631297"]:
            #     if "*650" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #59): {normarc_line}")
            #         continue
            #     if "*650" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #60): {marc21_line}")
            #         continue
            # 
            # # problem comparing dewey, but it looks acceptable
            # if identifier in ["373956", "631745"]:
            #     if normarc_line_property == "dc:subject.dewey":
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #61): {normarc_line}")
            #         continue
            #     if marc21_line_property == "dc:subject.dewey":
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #62): {marc21_line}")
            #         continue
            # 
            # # problem comparing *650, but it looks acceptable
            # if identifier in ["632188"]:
            #     if "*650" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #61): {normarc_line}")
            #         continue
            #     if "*650" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #62): {marc21_line}")
            #         continue
            # 
            # # titles should be fixed now, skip until next conversion
            # if identifier in ["381450", "581450", "610955"]:
            #     if normarc_line_property.startswith("dc:title"):
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #63): {normarc_line}")
            #         continue
            #     if marc21_line_property.startswith("dc:title"):
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #64): {marc21_line}")
            #         continue
            # 
            # # problem with converting *110$q, ignore for now
            # if identifier in ["564997", "631297", "562369", "564460", "580488", "581147", "582956", "618035", "619495", "621295",
            #                   "623212", "624798", "626790", "628669", "630760", "680488", "681147", "682956"]:
            #     if "*110" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #63): {normarc_line}")
            #         continue
            #     if "*110" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #64): {marc21_line}")
            #         continue
            # 
            # # it's unclear how "Originaltittel mangler" should be converted, ignore for now
            # if identifier in ["106246", "106268", "106351", "106371", "180000", "181890", "283877", "381890", "383011", "383223",
            #                   "383270", "383877", "566475", "583223", "609377", "609716", "609864", "610074", "610139", "610178",
            #                   "611036", "616020", "680440", "681890", "683011", "683270", "803688"]:
            #     if "*" in normarc_line_comment and normarc_line_comment.split("*")[1].split()[0].split("$")[0] in ["246", "500", "574"]:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #65): {normarc_line}")
            #         continue
            #     if "*" in marc21_line_comment and marc21_line_comment.split("*")[1].split()[0].split("$")[0] in ["246", "500", "574"]:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #66): {marc21_line}")
            #         continue
            # 
            # # unimportent issue when converting *245$a with trailing semicolon, can be fixed manually before or after conversion
            # if identifier in ["610415"]:
            #     if "*245$b" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #63): {normarc_line}")
            #         continue
            #     if "*245$b" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #64): {marc21_line}")
            #         continue
            # 
            # # authority registry ID disappears in conversion, ignore for now
            # if identifier in ["610434", "612316", "612316"]:
            #     if "*511" in normarc_line_comment or "*700" in normarc_line_comment or "contributor-700" in normarc_line:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #65): {normarc_line}")
            #         continue
            #     if "*511" in marc21_line_comment or "*700" in marc21_line_comment or "contributor-700" in marc21_line:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #66): {marc21_line}")
            #         continue
            # 
            # # bad conversion of *245, issue has been reported, ignore for now
            # if identifier in ["612820"]:
            #     if "*245" in normarc_line_comment or normarc_line_property == "sortingKey":
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #67): {normarc_line}")
            #         continue
            #     if "*245" in marc21_line_comment or marc21_line_property == "sortingKey":
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #68): {marc21_line}")
            #         continue
            # 
            # 
            # # bad conversion of *511, issue has been reported, ignore for now
            # if identifier in ["626338", "626339", "626344", "627887", "627892"]:
            #     if "*511" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #67): {normarc_line}")
            #         continue
            #     if "*511" in marc21_line_comment:
            #         marc21_skip_lines.append(f"MARC21: skipped line {marc21_linenum+1} (reason #68): {marc21_line}")
            #         continue
            # 
            # 
            # # bad conversion of *574, issue has been reported, ignore for now
            # if identifier in ["612824"]:
            #     if "*574" in normarc_line_comment:
            #         normarc_skip_lines.append(f"NORMARC: skipped line {normarc_linenum+1} (reason #69): {normarc_line}")
            #         continue
            # 
            if normarc_line != marc21_line:
                if print_first_error_only and not error_has_occured or not print_first_error_only:
                    if not print_first_error_only and error_has_occured:
                        print("\n---\n")
                    if len(normarc_skip_lines) or len(marc21_skip_lines):
                        print("\n".join(normarc_skip_lines))
                        print("\n".join(marc21_skip_lines))
                        print()
                    
                    print("Lines are different:")
                    print(f"NORMARC (line{normarc_linenum + 1 : 3}) --> {normarc_line}  {normarc_line_comment}")
                    print(f"MARC21 (line{marc21_linenum + 1 : 3})  --> {marc21_line}  {marc21_line_comment}")
                    print()
                    
                    print("Lines are different (with context):")
                    print()
                    
                    # NORMARC lines with context
                    for prev_line in normarc[max(normarc_linenum - 2, 0) : normarc_linenum]:
                        print(f"                      {re.sub(r' +', ' ', prev_line.strip())}")
                    print(f"NORMARC (line{normarc_linenum + 1 : 3}) --> {normarc_line}  {normarc_line_comment}")
                    for next_line in normarc[normarc_linenum + 1 : min(normarc_linenum + 3, len(normarc) - 1)]:
                        print(f"                      {re.sub(r' +', ' ', next_line.strip())}")
                    
                    print()
                    
                    # MARC 21 lines with context
                    for prev_line in marc21[max(marc21_linenum - 2, 0) : marc21_linenum]:
                        print(f"                      {re.sub(r' +', ' ', prev_line.strip())}")
                    print(f"MARC21 (line{marc21_linenum + 1 : 3})  --> {marc21_line}  {marc21_line_comment}")
                    for next_line in marc21[marc21_linenum + 1 : min(marc21_linenum + 3, len(marc21) - 1)]:
                        print(f"                      {re.sub(r' +', ' ', next_line.strip())}")
                    
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
            infile = os.path.join(current_directory, "resources/dumpreg", marcname, f"data.{tablename}.txt")
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
                last_few = ""
                if len(identifiers) - successful < 100:
                    last_few = f" - {len(identifiers) - successful} remaining"
                print(f"{successful} of {len(identifiers)} successful so far ({int(10000 * successful / len(identifiers)) / 100}%){last_few}")
                print()
                print(f"{identifier}:")
                print(f"- NORMARC in: {normarc_file}")
                print(f"- MARC21 in: {marc21_file}")
                print(f"- NORMARC OPF out: {normarc_opf_file}")
                print(f"- MARC21 OPF out: {marc21_opf_file}")
                print()
                print("Library links:")
                print(f"Normarc: https://websok.nlb.no/cgi-bin/websok?tnr={identifier}")
                print(f"Marc 21: https://lydlab1.bib.no/cgi-bin/websok?tnr={identifier}")
                print()
                print("Open all in editor:")
                print(f"{config.get('editor', 'subl')} {normarc_opf_file} {marc21_opf_file} {normarc_source_file} {marc21_source_file}")
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
        mark_as_handled(identifier)
        continue

    success = False
    success = handle(identifier, detailed_comparison=detailed_comparison)
    
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
        if identifier in skip_records:
            mark_as_handled(identifier)
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

print(f"{(successful + failed)} of {len(identifiers)} processed")
