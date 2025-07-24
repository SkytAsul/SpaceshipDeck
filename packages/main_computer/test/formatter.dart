import 'package:main_computer/src/utils/formatter.dart';
import 'package:test/test.dart';

void main() {
  test("Empty object is inlined", () {
    expect(format("Object"), "Object");
    expect(format("Object[]"), "Object");
  });

  test("List without recursion", () {
    expect(format("[a, b, c]"), """
- a
- b
- c""");
  });

  test("Simple object without recursion", () {
    expect(format("Object[key1=a]"), """
Object
  key1: a""");
    expect(format("Object[key1=a, key2=b]"), """
Object
  key1: a
  key2: b""");
  });

  test("Ambiguous parameters", () {
    expect(format("Object[key1=A string, with = characters,key2=Normal]"), """
Object
  key1: A string, with = characters
  key2: Normal""");
  });

  test("Complex object", () {
    expect(
      format(
        "Object[key1=a, key2=Another[key=value, key2=Damn[hello=there]], key3=[a, b, c[d=v]]]",
      ),
      """
Object
  key1: a
  key2: Another
    key: value
    key2: Damn
      hello: there
  key3:
  - a
  - b
  - c
    d: v""",
    );
  });
}
