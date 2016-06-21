#jsonParser

Yet Another JSON parser for D.

#Features

* Easy to use D interface(at least, better than std.json)
* Parse JSON and Serialize JSON

#Documents
Here is simple Document.  
This sample requires to import these files:

* jsonParser/jsonStructure.d
* jsonParser/jsonParser.d

```d
import jsonParser.jsonStructure,
       jsonParser.jsonParser;
```

## Sample JSON
```json
{
  "string":"string",
  "integer": 123,
  "float": 1.23,
  "bool":true,
  "array": ["string", 123, 1.23],
  "object": {
    "string":"string",
    "integer": 123
  }
}
```

## Parsed Classes Model(image)
```
JSONObject {
  JSONNode("string",  JSONNodeValue<string>("string")),
  JSONNode("integer", JSONNodeValue<numeric>(123)),
  JSONNode("float",   JSONNodeValue<numeric>(1.23)),
  JSONNode("bool",    JSONNodeValue<bool>(true)),
  JSONNode("array",   JSONNodeValue<array>(
        JSONNodeValue<string>("string"),
        JSONNodeValue<numeric>(123),
        JSONNodeValue<numeric>(1.23)),
  JSONNode("object",  JSONNodeValue<JSONObject> {
    JSONNode("string",  JSONNodeValue<string>("string")),
    JSONNode("integer", JSONNodeValue<numeric>(123))
  })
}
```

##Parse JSON

```d
string text = `{
  "string":"string",
  "integer": 123,
  "float": 1.23,
  "bool":true,
  "array": ["string", 123, 1.23],
  "object": {
    "string":"string",
    "integer": 123
  }
}`;

JSONObject json = parseJSON(text);

dumpJSONString(json);


writeln(json["string"].str);
writeln(json["integer"].num);
writeln(json["float"].num);
writeln(json["bool"].boolean);
writeln(json["array"].getValue);
writeln(json["object"]["string"].str);
writeln(json["object"]["integer"].num);
```

## Serialize
```
JSONObject json = new JSONObject;

json.addNode(new JSONNode("string", "string"));
json.addNode(new JSONNode("integer", 123));
json.addNode(new JSONNode("float", 1.23));
json.addNode(new JSONNode("bool", true));
json.addNode(new JSONNode("array", 
      new JSONArray([
        new JSONNodeValue("string"),
        new JSONNodeValue(123),
        new JSONNodeValue(1.23)
      ])));
json.addNode(new JSONNode("object", new JSONObject([
        new JSONNode("string", "string"),
        new JSONNode("integer", 123)   
])));

  dumpJSONString(json);
/*
  above function works as:
  writeln(toJSON(json));
*/

string serialized = toJSON(json);
```

#Test
##Build

```zsh
$ dmd test.d source/jsonParser/jsonParser.d source/jsonParser/jsonStructure.d
```

##Run

```zsh
$ ./test
```

#License
MIT License.  See `LICENSE` file for the detail.  
Copyright (C) alphaKAI 2016 [http://alpha-kai-net.info](http://alpha-kai-net.info)
