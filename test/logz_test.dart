import 'package:flutter_test/flutter_test.dart';

import 'package:logz/logz.dart';

void main() {
  test('test logZ', () {
    final logZ = LogZ(zipPassword: '123456', logFilePrefix: 'testLog_');
    logZ.logToFile('Logging via logToFile function');
    logZ.logToFile('Line 2 of log');
  });
}
