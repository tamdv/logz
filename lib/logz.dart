import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logz/log_utils.dart';
import 'package:share_plus/share_plus.dart';

class LogZ {
  static final LogZ _instance = LogZ._internal();

  /// Singleton instance of LogZ. \
  /// [zipPassword] and [logFilePrefix] must be provided at first initialization. \
  /// [printLogs] indicates whether to print logs to console, default is true. \
  /// [zipPassword] is the password for the zipped log files. Use this password to unzip logs.zip file. \
  /// [logFilePrefix] is the prefix for log file names. For example, if set to 'appLog', log files will be named like 'appLog-12-31-2024.txt'.
  factory LogZ({
    required String zipPassword,
    required String logFilePrefix,
    bool printLogs = true,
  }) {
    LogUtils.shared.zipPassword = zipPassword;
    LogUtils.shared.logFilePrefix = logFilePrefix;
    _instance._isPrint = printLogs;
    return _instance;
  }

  final List<String> _buffer = [];
  bool _isFlushing = false;
  bool _isPrint = true;

  LogZ._internal();

  void logToFile(dynamic data) {
    Future.microtask(() {
      _log(data);
    });
  }

  void _log(dynamic data) {
    if (_isPrint) {
      if (kDebugMode) print(data);
    }
    _buffer.add(data.toString());

    if (!_isFlushing) {
      _isFlushing = true;
      Future.delayed(const Duration(seconds: 2), _flush);
    }
  }

  void _flush() async {
    if (_buffer.isNotEmpty) {
      final batch = List<String>.from(_buffer);
      _buffer.clear();
      await LogUtils.shared.writeLog(batch.join('\n'));
      await LogUtils.shared.deleteOldLogFiles();
    }
    _isFlushing = false;
  }

  ///return zip file
  Future<File> zipLog() async {
    return await LogUtils.shared.zipLog();
  }

  ///zip files for share
  void zipToShareLog() async {
    final file = await LogUtils.shared.zipLog();
    Share.shareXFiles([XFile(file.path)]);
  }
}
