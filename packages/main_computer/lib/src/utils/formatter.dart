final _structRegex = RegExp(
  r"^(?:(?<identifier>\w+)(?:\[(?<parameters>.*)\])?|\[(?<list>.*)\])$",
);
final _paramRegex = RegExp(r"^(?:\w+?=)");

String indent(int level) => "  " * level;

/// Formats a compact structured string to a pretty, multi-line, indented one.
///
/// The [structuredString] is expected to be in the recursive format
/// name[key1=<value1>,key2=<value2>,...] where values can also be structured.
String format(String structuredString) {
  var (formatted, _) = _format(structuredString, 0);
  return formatted;
}

(String formatted, bool softWrap) _format(String structuredString, int level) {
  var matcher = _structRegex.firstMatch(structuredString);
  if (matcher == null) {
    // format not recognized
    print("Failed to parse: $structuredString");
    return (structuredString, false);
  }

  String? identifier = matcher.namedGroup("identifier");
  if (identifier != null) {
    String builtString = identifier;

    String? parameters = matcher.namedGroup("parameters");
    if (parameters != null) {
      for (var (key, value) in _parseParameters(parameters)) {
        var (formatted, softWrap) = _format(value, level + 1);
        if (softWrap) {
          formatted = "\n$formatted";
        }
        builtString += "\n${indent(level + 1)}$key: $formatted";
      }
    }
    return (builtString, false);
  } else {
    return (
      matcher
          .namedGroup("list")!
          .split(",")
          .map(
            (line) => "${indent(level)}- ${_format(line.trim(), level + 1).$1}",
          )
          .join("\n"),
      true,
    );
  }
}

List<(String, String)> _parseParameters(String parameters) {
  int depth = 0;
  List<(String, String)> parsed = [];

  String key = "";
  String? value;

  for (var (i, codeUnit) in parameters.codeUnits.indexed) {
    switch (codeUnit) {
      case 91: // [
        depth++;
      case 93: // ]
        depth--;
      case 61 when depth == 0: // =
        // key end
        value = "";
      case 44 when depth == 0: // ,
        // value end
        parsed.add((key, value!.trim()));
        key = "";
        value = null;
      default:
        if (value == null) {
          key += String.fromCharCode(codeUnit);
        } else {
          value += String.fromCharCode(codeUnit);
        }
        break;
    }
  }

  if (value != null) {
    parsed.add((key, value.trim()));
  } else if (key.isNotEmpty) {
    throw Exception("Unfinished parameter $key");
  }
  return parsed;
}
