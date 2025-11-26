// ignore_for_file: unnecessary_getters_setters

import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'dart:convert';

class LogUtils {
  static final LogUtils shared = LogUtils._internal();
  LogUtils._internal();

  String? _cacheDirectoryPath;
  final Map<String, Future<void>> _fileLocks = {};

  LogUtils() {
    _initializeCacheDirectory();
  }

  String _zipPassword = '';
  String _logFilePrefix = '';

  String get zipPassword => _zipPassword;
  String get logFilePrefix => _logFilePrefix;

  set logFilePrefix(String logFilePrefix) {
    _logFilePrefix = logFilePrefix;
  }

  set zipPassword(String zipPassword) {
    _zipPassword = zipPassword;
  }

  Future<void> _initializeCacheDirectory() async {
    _cacheDirectoryPath = await _getCacheDirectory();
  }

  Future<String> _getCacheDirectory() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  Future<File> zipLog() async {
    try {
      // This Function only run if _cacheDirectoryPath is not initialize
      if (_cacheDirectoryPath == null) {
        await _initializeCacheDirectory(); // Call initialization if not done yet
      }
      final logFiles = Directory(_cacheDirectoryPath ?? '')
          .listSync()
          .where((file) => file is File && file.path.contains(logFilePrefix))
          .toList();

      if (logFiles.isEmpty) {
        throw Exception("No log files found to zip.");
      }

      final archive = Archive();
      for (var logFile in logFiles) {
        final file = File(logFile.path);
        final fileName = file.uri.pathSegments.last;
        final fileBytes = file.readAsBytesSync();
        archive.addFile(ArchiveFile(fileName, fileBytes.length, fileBytes));
      }

      final zipEncoder = ZipEncoder(password: zipPassword);
      final zipData = zipEncoder.encode(archive);

      final zipFilePath = '$_cacheDirectoryPath/logs.zip';
      final zipFile = File(zipFilePath)..writeAsBytesSync(zipData);

      return zipFile;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOldLogFiles() async {
    // This Function only run if _cacheDirectoryPath is not initialize
    if (_cacheDirectoryPath == null) {
      await _initializeCacheDirectory(); // Call initialization if not done yet
    }
    final directory = Directory(_cacheDirectoryPath ?? '');

    final files = await directory
        .list()
        .where(
          (file) =>
              file.path.contains(logFilePrefix) && file.path.endsWith('.txt'),
        )
        .toList();

    final now = DateTime.now();

    for (var file in files) {
      final fileName = file.path.split('/').last;
      // final match = RegExp(r'onelinksdk-(\d{2})-(\d{2})-(\d{4})\.txt').firstMatch(fileName);
      final match = RegExp(
        '${RegExp.escape(logFilePrefix)}(\\d{2})-(\\d{2})-(\\d{4})\\.txt',
      ).firstMatch(fileName);

      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = int.parse(match.group(3)!);

        final fileDate = DateTime(year, month, day);

        // Delete if file is older than 7 days
        if (now.difference(fileDate).inDays > 7) {
          await File(file.path).delete();
        }
      }
    }
  }

  Future<String> _createHeader() async {
    final deviceInfo = DeviceInfoPlugin();
    String deviceDetails;
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceDetails =
          '''
Device Manufacturer: ${androidInfo.manufacturer}
Device Model       : ${androidInfo.model}
OS Version         : Android ${androidInfo.version.sdkInt}''';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceDetails =
          '''
Device Manufacturer: Apple
Device Model       : ${iosInfo.utsname.machine}
OS Version         : iOS ${iosInfo.systemVersion}''';
    } else {
      deviceDetails = 'Unknown Platform';
    }

    final packageInfo = await PackageInfo.fromPlatform();

    return '''
>>>>>>>>>>>>>>> File Header >>>>>>>>>>>>>>>>>>
$deviceDetails
App Name           : ${packageInfo.appName}
App VersionName    : ${packageInfo.version}
App VersionCode    : ${packageInfo.buildNumber}
<<<<<<<<<<<<<<<<< File Header <<<<<<<<<<<<<<<<
''';
  }

  String _getFormattedTimestamp() {
    return DateTime.now().toIso8601String();
  }

  String _serializeData(dynamic data) {
    if (data is String) {
      return data;
    } else if (data is Map || data is List) {
      return jsonEncode(data);
    } else {
      return data.toString();
    }
  }

  Future<void> writeLog(String data) async {
    if (_cacheDirectoryPath == null) {
      await _initializeCacheDirectory();
    }

    final now = DateTime.now();
    final logFilePath =
        '$_cacheDirectoryPath/$logFilePrefix-${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}.txt';

    final serializedData = _serializeData(data);
    final timestamp = _getFormattedTimestamp();
    final content = '$timestamp $serializedData\n';

    _fileLocks[logFilePath] ??= Future.value();

    _fileLocks[logFilePath] = _fileLocks[logFilePath]!
        .then((_) async {
          final logFile = File(logFilePath);

          if (!await logFile.exists()) {
            final header = await _createHeader();
            await logFile.writeAsString(header, mode: FileMode.write);
          }

          await logFile.writeAsString(content, mode: FileMode.append);
        })
        .catchError((e) {});

    return _fileLocks[logFilePath];
  }
}
