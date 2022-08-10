#!/usr/bin/python3

import os
import sys
from pprint import pprint
from lxml import etree as ElementTree

current_directory = os.path.dirname(__file__)
target = os.path.join(current_directory, "target")


def parse_opf(path):
    raw_lines = []
    with open(path) as f:
        raw_lines = [line.strip() for line in f.readlines()]
    
    lines = []
    for line in raw_lines:
        if "<metadata" in line or "</metadata" in line:
            continue
        [element, comment] = (line, None)
        if "<!--" in line:
            [element, comment] = line.split("<!--", 1)
        tag = element.split("<")[1].split(">")[0].split(" ")[0]
        attributes = element.split(">")[0].split("<")[1].split(" ")[1:]  # get the string in the first tag, and split on space characters
        attributes = {attribute.split("=")[0]: attribute.split("=")[1] for attribute in attributes}  # split attribute name and value on equals
        attributes = {key: attributes[key][1:-1] for key in attributes}  # remove quotes surrounding the value
        name = attributes.get("property", tag)  # use the property attribute if present, otherwise the tag name
        id = attributes.get("id", None)
        refines = attributes["refines"][1:] if "refines" in attributes else None
        attributes = {key: attributes[key] for key in attributes if key not in ["property"]}
        value = element.split(">", 1)[1].split("<")[0]  # get the value between the start and end tag
        comment = comment.split("-->")[0].strip() if comment else comment
        lines.append([name, value, id, refines, comment])
    
    lines_nested = []
    for [name, value, id, refines, comment] in lines:
        if refines:
            continue
        if id:
            refinements = []
            for [n, v, i, r, c] in lines:
                if r is None:
                    continue  # skip meta elements without a refines attribute
                assert i is None, f"meta elements with a refines attribute must not have an id attribute. Found:\n{n}\n{v}\n{i}\n{r}\n{c}"
                if r == id:  # refines attribute refers to the id we're looking for
                    refinements.append([n, v, c])
        lines_nested.append([name, value, comment, refinements])
    
    for line in lines_nested:
        pprint(line)
    return lines_nested


def parse_marcxchange(path):
    marcxchange = ElementTree.parse(path)
    
    nsmap = {"marcxchange": "info:lc/xmlns/marcxchange-v1"}

    record = marcxchange.xpath("/marcxchange:record", namespaces=nsmap)[0]
    controlfields = record.xpath("marcxchange:controlfield", namespaces=nsmap)
    datafields = record.xpath("marcxchange:datafield", namespaces=nsmap)

    result = {}

    result["format"] = record.attrib.get("format")
    result["type"] = record.attrib.get("type")

    for controlfield in controlfields:
        tag = controlfield.attrib["tag"]
        value = controlfield.text
        if tag not in result:
            result[tag] = []
        result[tag].append(value)
    
    for datafield in datafields:
        tag = datafield.attrib["tag"]
        ind1 = datafield.attrib["ind1"]
        ind2 = datafield.attrib["ind2"]
        subfields = []
        for subfield in datafield.xpath("marcxchange:subfield", namespaces=nsmap):
            code = subfield.attrib["code"]
            value = subfield.text
            subfields.append([code, value])
        if tag not in result:
            result[tag] = []
        result[tag].append([ind1, ind2, subfields])
    
    pprint(result)
    return result


# recursive assertions, useful to better pinpoint where the difference between actual results and expected results are
def assert_result_equals(actual, expected, generic_message, position="actual", _root_actual=None):
    assert type(actual) == type(expected) or actual is None or expected is None, (
        f"{position}: types are not equal, expected {type(expected)} but found {type(actual)}\n\nExpected {type(expected)}:\n{pformat(expected, sort_dicts=False)}\n\nActual {type(actual)}:\n{pformat(actual, sort_dicts=False)}"
    )

    equal = True

    if _root_actual is None:
        _root_actual = actual

    if isinstance(actual, list):
        assert len(actual) == len(expected), (
            f"{position}: list length is not as expected, expected {len(expected)} but found {len(actual)}"
            + f"\n\nExpected list:\n[\n"
            + "\n".join([pformat(item, sort_dicts=False) + ',' for item in expected])
            + "\n]"
            + f"\n\nActual list:\n[\n"
            + "\n".join([pformat(item, sort_dicts=False) + ',' for item in actual])
            + "\n]"
        )
        for i in range(len(actual)):
            equal = equal and assert_result_equals(actual[i], expected[i], generic_message, position=f"{position}[{i}]", _root_actual=_root_actual)

    elif isinstance(actual, dict):
        for actual_key in actual:
            assert actual_key in expected, f"{position}['{actual_key}']: found unexpected dict key: {actual_key}\n\nExpected dictionary:\n{pformat(expected, sort_dicts=False)}\n\nActual dictionary:\n{pformat(actual, sort_dicts=False)}"
        for expected_key in expected:
            assert expected_key in actual, f"{position}['{expected_key}']: missing dict key: {expected_key}\n\nExpected dictionary:\n{pformat(expected, sort_dicts=False)}\n\nActual dictionary:\n{pformat(actual, sort_dicts=False)}"
        for key in actual:
            if key == "md5" and expected[key] == "...":
                continue  # ignore
            equal = equal and assert_result_equals(actual[key], expected[key], generic_message, position=f"{position}['{key}']", _root_actual=_root_actual)

    else:
        equal = equal and actual == expected

    assert equal, (
        f"{position}: {generic_message}.\n\nExpected ({type(expected)}):\n{expected}\n\n"
        + f"Was ({type(actual)}):\n{actual}"
        # + f"\n\nFull results:\n{pformat(_root_actual, sort_dicts=False)}\n"
    )

    return equal


def compare(identifier, expected, result):
    include_fields = ["identifier"]

    expected = {key: expected[key] for key in expected if key in include_fields}
    result = {key: result[key] for key in result if key in include_fields}

    success = assert_result_equals(result, expected, "result is not as expected")

    return success


def handle(identifier):
    global marc_source_dir
    global opf_source_dir

    print(f"handle {identifier} here")

    marcxchange = os.path.join(marc_source_dir, f"{identifier}.xml")
    expected_opf = os.path.join(opf_source_dir, f"{identifier}.opf")
    expected = parse_opf(expected_opf)
    result = parse_marcxchange(marcxchange)
    success = compare(identifier, expected, result)

    return success


marc_source_dir = os.path.join(target, "records", "marc21", "vmarc")
opf_source_dir = os.path.join(target, "opf", "marc21")
assert os.path.isdir(marc_source_dir)
assert os.path.isdir(opf_source_dir)

marc_files = set([file[:-4] for file in os.listdir(marc_source_dir) if file.endswith(".xml")])
opf_files = set([file[:-4] for file in os.listdir(opf_source_dir) if file.endswith(".opf")])
identifiers = marc_files.intersection(opf_files)
identifiers = [str(identifier) for identifier in sorted([int(ident) for ident in identifiers])]

for identifier in identifiers:
    success = False
    try:
        success = handle(identifier)
    except Exception as e:
        print(f"An error occured when handling {identifier}: {e}")
        raise
    
    sys.exit(1)  # …for now
