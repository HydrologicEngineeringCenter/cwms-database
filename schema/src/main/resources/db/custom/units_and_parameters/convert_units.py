import json

data_out = []
data = json.load(open("unit_definitions.json"))
for v in data:
    print(str(v))
    unit = {}
    unit["abstract_parameter"] = v[0]
    unit["abbr"] = v[1]
    unit["system"] = v[2]
    unit["name"] = v[3]
    unit["description"] = v[4]
    data_out.append(unit)


json.dump(data_out,open("unit2.json","wt"),indent=4)