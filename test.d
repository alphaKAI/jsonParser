import std.algorithm,
       std.array,
       std.stdio;
import jsonParser.jsonStructure;
import jsonParser.jsonParser;

void main() {

  writeln("---parse test---");
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

  writeln("---json serialize test---");
  json = new JSONObject;

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
}
