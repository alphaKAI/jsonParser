module jsonParser.jsonParser;
import std.conv,
       std.math;
import jsonParser.jsonStructure;

private {
  long   at;
  char ch;
  char[char] escapee;
  char[] text;
}

private void error(string errStr) {
  import std.stdio;
  writeln("syntaxError");
  writeln("message: ", errStr);
  writeln("at: ", at);
  writeln("text: ", text);

  throw new Error(errStr);
}

private void initJSONParser() {
  at = 0;
  ch = ch.init;
  text = text.init;
  escapee = [
    '\"': '\"',
    '\\': '\\',
    '/':  '/',
    'b':  'b',
    'f':  '\f',
    'n':  '\n',
    'r':  '\r',
    't':  '\t'
  ];
}

private char next() {
  if (at < text.length) {
    ch = text[at];
    at += 1;
    return ch;
  } else {
    ch = ' ';
    return ' ';
  }
}

private char next(char c) {
  if (c && c != ch) {
    error("Expected '" ~ c ~ "' instade of '" ~ ch ~ "'");
  }

  return next;
}

private JSONNodeValue numberProc() {
  float _number;
  char[] str;

  if (ch == '-') {
    str = ['-'];
    next('-');
  }

  while ('0' <= ch && ch <= '9') {
    str ~= ch;
    next;
  }

  if (ch == '.') {
    str ~= '.';

    while (next && '0' <= ch && ch <= '9') {
      str ~= ch;
    }
  }

  if (ch == 'e' || ch == 'E') {
    str ~= ch;
    next;

    if (ch == '-' || ch == '+') {
      str ~= ch;
      next;
    }

    while ('0' <= ch && ch <= '9') {
      str ~= ch;
      next;
    }
  }

  _number = str.to!float;

  if (isNaN(_number)) {
    error("Bad number");
    return null;
  } else {
    JSONNodeValue jsonNodeValue = new JSONNodeValue(JSONNodeValueType.Numeric);
    jsonNodeValue.setValue(_number);
    return jsonNodeValue;
  }
}

private JSONNodeValue stringProc() {
  float hex,
       i,
       uffff;
  char[] str;

  if (ch == '"') {
    while (next()) {
      if (ch == '"') {
        next;
        JSONNodeValue jsonNodeValue = new JSONNodeValue(JSONNodeValueType.String);
        jsonNodeValue.setValue(str.to!string);
        return jsonNodeValue;
      } else if (ch == '\\') {
        next;
        if (ch == 'u') {
          uffff = 0;
          for (i = 0; i < 4; i++) {
            hex = next().to!float;
            if (!isFinite(hex)) {
              break;
            }
            uffff = uffff * 16 + hex;
          }
          str ~= (cast(char)uffff).to!string;
        } else if (ch in escapee) {
          str ~= escapee[ch];
        } else {
          break;
        }
      } else {
        str ~= ch;
      }
    }
  }

  error("Bad String");
  return null;
}

private void white() {
  while (ch && ch <= ' ') {
    next;
  }
}

private JSONNodeValue wordProc() {
  JSONNodeValue jsonNodeValue;
  switch(ch) {
    case 't':
      next('t');
      next('r');
      next('u');
      next('e');
      jsonNodeValue = new JSONNodeValue(JSONNodeValueType.Boolean);
      jsonNodeValue.setValue(true);
      return jsonNodeValue;
    case 'f':
      next('f');
      next('a');
      next('l');
      next('s');
      next('e');
      jsonNodeValue = new JSONNodeValue(JSONNodeValueType.Boolean);
      jsonNodeValue.setValue(false);
      return jsonNodeValue;
    case 'n':
      next('n');
      next('u');
      next('l');
      next('l');
      jsonNodeValue = new JSONNodeValue(JSONNodeValueType.Boolean);
      jsonNodeValue.setValue(new JSONNULL);
      return jsonNodeValue;
    default: break;
  }

  error("Unexpected '" ~ ch ~ "'");
  return null;
}

private JSONNodeValue arrayProc() {
  JSONArray array = new JSONArray([]);
  JSONNodeValue jsonNodeValue = new JSONNodeValue(JSONNodeValueType.Array);

  if (ch == '[') {
    next('[');
    white();
    if (ch == ']') {
      next(']');
      jsonNodeValue.setValue(array);
      return jsonNodeValue;
    }

    while (ch) {
      array.addValue(valueProc());
      white();
      if (ch == ']') {
        next(']');
        jsonNodeValue.setValue(array);
        return jsonNodeValue;
      }
      next(',');
      white;
    }
  }

  throw new Error("Bad Array");
}

private JSONNodeValue objectProc() {
  string key;
  JSONNodeValue jsonNodeValue = new JSONNodeValue(JSONNodeValueType.JSONObject);
  JSONObject object = new JSONObject;

  if (ch == '{') {
    next('{');
    white;
    if (ch == '}') {
      next('}');
      jsonNodeValue.setValue(object);
      return jsonNodeValue;
    }

    while (ch) {
      key = stringProc().getValue!(JSONNodeValueType.String);
      white;
      next(':');
      object.addNode(new JSONNode(key, valueProc()));

      white;
      if (ch == '}') {
        next('}');
        jsonNodeValue.setValue(object);
        return jsonNodeValue;
      }

      next(',');
      white();
    }
  }

  throw new Error("Bad Object");
}

private JSONNodeValue valueProc() {
  white;

  switch (ch) {
    case '{':
      return objectProc;
    case '[':
      return arrayProc;
    case '"':
      return stringProc;
    case '-':
      return numberProc;
    default:
      return ('0' <= ch && ch <= '9') ? numberProc : wordProc;
  }
}

JSONObject parseJSON(string _text) {
  initJSONParser;
  text = _text.to!(char[]);
  ch = ' ';
  JSONNodeValue result = valueProc;

  if (ch != ' ') {
    throw new Error("SyntaxError");
  }

  JSONObject object = result.getValue!(JSONNodeValueType.JSONObject);

  return object;
}

unittest {
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
}
