module jsonParser.jsonStructure;
import std.algorithm,
       std.array,
       std.range,
       std.stdio,
       std.conv;

/+
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

Mapping to D's JSON Handling class ->

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
+/

enum JSONNodeValueType {
  Numeric,
  String,
  Boolean,
  Array,
  NULL,
  JSONObject
}

private mixin template JSONNodeValueBase(TYPE) {
  private TYPE value;

  this (TYPE value) {
    this.value = value;
  }

  @property void setValue(TYPE value) {
    this.value = value;
  }

  @property TYPE getValue() {
    return this.value;
  }
}

class JSONNumeric { mixin JSONNodeValueBase!float;  }
class JSONString  { mixin JSONNodeValueBase!string; }
class JSONBoolean { mixin JSONNodeValueBase!bool;   }
class JSONNULL {
  void setValue(X)(X v) { this.setValue; }
  void setValue()       { throw new Exception("Can not apply any value to null object"); }
  string getValue()     { return "null"; }
}

class JSONNodeValue {
  JSONNodeValueType type;
  private {
    JSONNumeric jsonNumeric;
    JSONString  jsonString;
    JSONBoolean jsonBoolean;
    JSONArray   jsonArray;
    JSONNULL    jsonNULL;
    JSONObject  jsonObject;
  }

  this(JSONNodeValueType type) {
    this.type = type;
  }

  this(X)(X value) {
    this.setValue(value);
  }

  private static genSetValueString(T, alias R, alias L, R2)() {
    return "void setValue(" ~ T.stringof ~ " value) {"
         ~ "this.type        = JSONNodeValueType." ~ R.stringof ~ ";"
         ~ "this." ~ L.stringof ~ " = new " ~ R2.stringof ~ "(value);"
         ~ "}";
  }

  private static genSetValueString(T, alias R, alias L)() {
    return "void setValue(" ~ T.stringof ~ " value) {"
         ~ "this.type        = JSONNodeValueType." ~ R.stringof ~ ";"
         ~ "this." ~ L.stringof ~ " = value;"
         ~ "}";
  }

  mixin(genSetValueString!(float,  JSONNodeValueType.Numeric, jsonNumeric, JSONNumeric));
  mixin(genSetValueString!(string, JSONNodeValueType.String,  jsonString,  JSONString));
  mixin(genSetValueString!(bool,   JSONNodeValueType.Boolean, jsonBoolean, JSONBoolean));
  void setValue(JSONNULL   value) { this.type = JSONNodeValueType.NULL; }
  mixin(genSetValueString!(JSONArray,  JSONNodeValueType.Array,      jsonArray));
  mixin(genSetValueString!(JSONObject, JSONNodeValueType.JSONObject, jsonObject));

  private auto getValue(X)(X val) {
    if (val is null) { throw new Exception("The value haven't set!");}
    else { return val.getValue; }
  }

  string getValue() {
    string returnString;

    if (type == JSONNodeValueType.Numeric) {
      returnString = getValue(this.jsonNumeric).to!string;
    } else if (type == JSONNodeValueType.String) {
      returnString = "\"" ~ getValue(this.jsonString).to!string ~ "\"";
    }else if (type == JSONNodeValueType.Boolean) {
      returnString = getValue(this.jsonBoolean).to!string;
    } else if (type == JSONNodeValueType.Array) {
      returnString = "[" ~ getValue(this.jsonArray).map!(x => x.getValue).join(", ") ~ "]";
    } else if (type == JSONNodeValueType.NULL) {
      returnString = getValue(this.jsonNULL).to!string;  
    } else if (type == JSONNodeValueType.JSONObject) {
      returnString = this.jsonObject.to!string;
    }

    return returnString;
  }

  private static genGetValueString(T, alias R, alias L)() {
    return T.stringof ~ " getValue(JSONNodeValueType type)() if (type == JSONNodeValueType." ~ R.stringof ~ ") {"
           ~ "return getValue(this." ~ L.stringof ~");"
           ~ "}";
  } 

  mixin(genGetValueString!(float,     JSONNodeValueType.Numeric, jsonNumeric));
  mixin(genGetValueString!(string,    JSONNodeValueType.String,  jsonString));
  mixin(genGetValueString!(bool,      JSONNodeValueType.Boolean, jsonBoolean));
  mixin(genGetValueString!(JSONArray, JSONNodeValueType.Array,   jsonArray));
  mixin(genGetValueString!(JSONNULL,  JSONNodeValueType.NULL,    jsonNULL));
  JSONObject getValue(JSONNodeValueType type)() if (type == JSONNodeValueType.JSONObject) { return this.jsonObject; }

  private static genGetProperty(T, string propertyName, alias JNVT, alias L)() {
    return "@property " ~ T.stringof ~ " " ~ propertyName ~ "() {"
            ~ "if (this.type == JSONNodeValueType." ~ JNVT.stringof ~ ") {"
            ~ "  return this." ~ L.stringof~ ".getValue;"
            ~ "} else {"
            ~ ` throw new Error("This value is not ` ~ JNVT.stringof ~ "\");"
            ~ "}"
          ~ "}";
  }

  mixin(genGetProperty!(float,     "num",     JSONNodeValueType.Numeric, jsonNumeric));
  mixin(genGetProperty!(string,    "str",     JSONNodeValueType.String,  jsonString));
  mixin(genGetProperty!(bool,      "boolean", JSONNodeValueType.Boolean, jsonBoolean));

  @property JSONArray array() {
    if (this.type == JSONNodeValueType.Array) {
      return this.jsonArray;
    } else {
      throw new Error("This value is not Array, this value is " ~ this.type.stringof);
    }
  }

  @property string NULL() {
    if (this.type == JSONNodeValueType.NULL) {
      return this.jsonNULL.getValue;
    } else {
      throw new Error("This value is not NULL, this value is " ~ this.type.stringof);
    }
  }

  @property JSONNodeValueType getType() {
    return this.type;
  }

  JSONNodeValue opIndex(string key) {
    if (this.type == JSONNodeValueType.JSONObject) {
      if (key in this.jsonObject) {
        return this.jsonObject[key];
      } else {
        throw new Exception("No such a key: " ~ key);
      }
    } else {
      throw new Exception("Invalied index operator");
    }
  }
}

class JSONArray {
  mixin JSONNodeValueBase!(JSONNodeValue[]);

  void addValue(JSONNodeValue value) { this.value ~= value; }

  JSONNodeValue opIndex(size_t idx) {
    if (idx < this.value.length) {
      return this.value[idx];
    } else {
      throw new Error("array index is out of range");
    }
  }
}

class JSONObject {
  mixin JSONNodeValueBase!(JSONNode[string]);

  alias value this;

  this() {}

  this(JSONNode[] nodes) {
    foreach (node; nodes) {
      this.addNode(node);
    }
  }

  void addNode(JSONNode node) {
    this.value[node.key] = node;
  }

  JSONNodeValue opIndex(string key) {
    if (key in this.value) {
      return this.value[key].value;
    } else {
      throw new Exception("No such a key: " ~ key);
    }
  }
}

class JSONNode {
  string            key;
  JSONNodeValue     value;
  JSONNodeValueType type;

  private static genThisString(L, alias R)() {
    return "this(string key, " ~ L.stringof ~ " value)     { this.key = key; this.type = JSONNodeValueType." ~ R.stringof ~ ";    this(); setValue(value); }";
  }

  this(string key, JSONNodeValue value) {
    this.key   = key;
    this.value = value;
    this.type  = value.type;
  }

  mixin(genThisString!(float, JSONNodeValueType.Numeric));
  mixin(genThisString!(string, JSONNodeValueType.String));
  mixin(genThisString!(bool, JSONNodeValueType.Boolean));
  mixin(genThisString!(JSONNULL, JSONNodeValueType.NULL));
  mixin(genThisString!(JSONArray, JSONNodeValueType.Array));
  mixin(genThisString!(JSONObject, JSONNodeValueType.JSONObject));

  private this() { value = new JSONNodeValue(type); }

  @property void setValue(X)(X value) {
    this.value.setValue(value);
  }

  @property JSONNodeValue getValue() {
    return this.value;
  }
}

string toJSON(JSONObject json, int depth = 0) {
  string serialized;
  size_t c;
  serialized ~= "{\n";

  foreach(string key, JSONNode node; json.getValue) {
    if (node.type == JSONNodeValueType.JSONObject) {
      if (c) {
        writeln(",");
      }
      foreach (_; ((depth + 1) * 2).iota) { serialized ~= " "; }
      serialized ~= ("\"" ~ key ~ "\" : ");
      serialized ~= toJSON(node.getValue.getValue!(JSONNodeValueType.JSONObject), depth + 1);
    } else {
      if (c) {
        serialized ~= ",\n";
      }
      foreach (_; ((depth + 1) * 2 ).iota) { serialized ~= " "; }
      serialized ~= ("\"" ~ key ~ "\" : "~ node.getValue.getValue());

    }

    c++;
  }
  serialized ~= "\n";

  foreach (_; (depth * 2).iota) { serialized ~= " "; }
  serialized ~= ("}");
  return serialized;
}

void dumpJSONString(JSONObject json) {
  writeln(toJSON(json));
}

unittest {
  writeln("TEST FOR JSON Serialize");
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
}
