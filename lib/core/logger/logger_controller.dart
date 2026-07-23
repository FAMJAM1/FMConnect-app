import 'dart:io';

import 'package:hiddify/core/logger/custom_logger.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:loggy/loggy.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:rxdart/rxdart.dart';

class LoggerController extends LoggyPrinter with InfraLogger {
  LoggerController(this.consolePrinter, this.otherPrinters);

  final LoggyPrinter consolePrinter;
  final Map<String, LoggyPrinter> otherPrinters;

  // in-memory ring buffer of app-side logs, for the in-app Logs screen
  final List<LogRecord> _appLogBuffer = [];
  final appLogController = BehaviorSubject<List<LogRecord>>.seeded(const []);

  static LoggerController get instance => _instance;

  static late LoggerController _instance;

  static void preInit() {
    Loggy.initLoggy(logPrinter: const ConsolePrinter());
  }

  static void init(String appLogPath) {
    _instance = LoggerController(const ConsolePrinter(), {"app": kIsWeb ? const ConsolePrinter() : FileLogPrinter(appLogPath)});
    Loggy.initLoggy(logPrinter: _instance);
  }

  static Future<void> postInit(bool debugMode) async {
    final logLevel = debugMode && false ? LogLevel.all : LogLevel.info;
    final logToFile = debugMode || (!Platform.isAndroid && !Platform.isIOS);

    if (!logToFile || kIsWeb) _instance.removePrinter("app");

    Loggy.initLoggy(logPrinter: _instance, logOptions: LogOptions(logLevel));
  }

  void addPrinter(String name, LoggyPrinter printer) {
    loggy.debug("adding [$name] printer");
    otherPrinters.putIfAbsent(name, () => printer);
  }

  void clearAppLogBuffer() {
    _appLogBuffer.clear();
    appLogController.add(const []);
  }

  void removePrinter(String name) {
    loggy.debug("removing [$name] printer");
    final printer = otherPrinters[name];
    if (printer case FileLogPrinter()) {
      printer.dispose();
    }
    otherPrinters.remove(name);
  }

  @override
  void onLog(LogRecord record) {
    consolePrinter.onLog(record);
    for (final printer in otherPrinters.values) {
      printer.onLog(record);
    }
    _appLogBuffer.add(record);
    if (_appLogBuffer.length > 300) {
      _appLogBuffer.removeAt(0);
    }
    appLogController.add(List.unmodifiable(_appLogBuffer));
  }
}
