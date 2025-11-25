A lightweight, easy-to-use structured logging package for Dart and Flutter.

Features
- Write logs data into txt files
- Zip txt files into logs.zip with password to unzip
- Share logs.zip file to outside

Getting started
1. Add to pubspec.yaml:
```yaml
dependencies:
    logz: ^0.0.1
```
2. Import and initialize:
```dart
import 'package:logz/logz.dart';

final logZ = LogZ(zipPassword: 'PASSWORD_TO_UNZIP_FILE', logFilePrefix: 'FILE_NAME_PREFIX');
```

Usage
- Basic:
```dart
logZ.logToFile('Logging via logToFile function');
logZ.zipToShareLog();
final zipFile = await logZ.zipLog();
```

Additional information
- See /example for complete examples.
- Contributing: open issues or PRs on the repository; follow repository contribution guidelines.
- License: MIT (or replace with your chosen license).
- For questions or feature requests, open an issue on the project's issue tracker.
