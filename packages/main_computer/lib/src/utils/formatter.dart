final _structRegex = RegExp(
  r"^(?:(?<identifier>\w+)(?:\[(?<parameters>.*)\])?|\[(?<list>.*)\])$",
);
final _paramRegex = RegExp(r"^\s*\w+?=");

String _indent(int level) => "  " * level;

extension ObjectStringFormat on Object {
  /// Formats the string representation of this object.
  String toFormattedString() => format(toString());
}

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
        } else {
          formatted = " $formatted";
        }
        builtString += "\n${_indent(level + 1)}$key:$formatted";
      }
    }
    return (builtString, false);
  } else {
    var items = matcher.namedGroup("list")!;
    if (items.trim().isEmpty) {
      return ("[]", false);
    }
    return (
      _parseListItems(items)
          .map((line) => "${_indent(level)}- ${_format(line.trim(), level).$1}")
          .join("\n"),
      true,
    );
  }
}

List<(String, String)> _parseParameters(String params) {
  int depth = 0;
  List<(String, String)> parsed = [];

  String key = "";
  String? value;

  for (var (i, codeUnit) in params.codeUnits.indexed) {
    switch (codeUnit) {
      case 91 when value != null: // [
        depth++;
        value += "[";
      case 93 when value != null: // ]
        depth--;
        value += "]";
      case 61 when depth == 0 && value == null: // =
        // key end
        value = "";
      case 44
          when depth == 0 && _paramRegex.hasMatch(params.substring(i + 1)): // ,
        // value end

        parsed.add((key.trim(), value!.trim()));
        key = "";
        value = null;
      case _:
        if (value == null) {
          key += String.fromCharCode(codeUnit);
        } else {
          value += String.fromCharCode(codeUnit);
        }
    }
  }

  if (value != null) {
    parsed.add((key.trim(), value.trim()));
  } else if (key.isNotEmpty) {
    throw Exception("Unfinished parameter $key");
  }
  return parsed;
}

List<String> _parseListItems(String list) {
  int depth = 0;
  List<String> parsed = [];

  String value = "";
  for (var codeUnit in list.codeUnits) {
    switch (codeUnit) {
      case 91: // [
        depth++;
        value += "[";
      case 93: // ]
        depth--;
        value += "]";
      case 44 when depth == 0: // ,
        // value end
        parsed.add(value.trim());
        value = "";
      case _:
        value += String.fromCharCode(codeUnit);
    }
  }

  parsed.add(value);
  return parsed;
}
