// A tiny test harness so the engine can be checked with plain `dart run`,
// without downloading package:test. Swap to package:test any time later:
// `check` → `test`, `expectThat(x, ...)` → `expect(x, isTrue)`.

class CheckFailure implements Exception {
  final String message;
  CheckFailure(this.message);
  @override
  String toString() => message;
}

int _passed = 0;
final List<String> _failed = <String>[];

void check(String name, void Function() body) {
  try {
    body();
    _passed++;
    print('  ok    $name');
  } catch (e) {
    _failed.add(name);
    print('  FAIL  $name\n        $e');
  }
}

void expectThat(bool condition, String what) {
  if (!condition) throw CheckFailure(what);
}

void expectEqual(Object? actual, Object? expected, String what) {
  if (actual != expected) {
    throw CheckFailure('$what: expected $expected, got $actual');
  }
}

void expectClose(double actual, double expected, double tolerance, String what) {
  if ((actual - expected).abs() > tolerance) {
    throw CheckFailure('$what: expected $expected ± $tolerance, got $actual');
  }
}

/// Prints the summary; returns the number of failures.
int report() {
  print('\n$_passed passed, ${_failed.length} failed');
  return _failed.length;
}
