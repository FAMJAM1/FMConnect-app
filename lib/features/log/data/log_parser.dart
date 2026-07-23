// ignore_for_file: parameter_assignments

import 'package:dartx/dartx.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart' as pb;
import 'package:loggy/loggy.dart' as loggyl;
import 'package:tint/tint.dart';

abstract class LogParser {
  static LogEntity parseLogRecord(loggyl.LogRecord record) {
    final priority = record.level.priority;
    final LogLevel level;
    if (priority <= loggyl.LogLevel.debug.priority) {
      level = LogLevel.debug;
    } else if (priority <= loggyl.LogLevel.info.priority) {
      level = LogLevel.info;
    } else if (priority <= loggyl.LogLevel.warning.priority) {
      level = LogLevel.warn;
    } else {
      level = LogLevel.error;
    }
    return LogEntity(level: level, time: record.time, message: record.message);
  }

  static LogEntity parseLogProto(pb.LogMessage message) {
    final level = switch (message.level) {
      pb.LogLevel.DEBUG => LogLevel.debug,
      pb.LogLevel.INFO => LogLevel.info,
      pb.LogLevel.WARNING => LogLevel.warn,
      pb.LogLevel.ERROR => LogLevel.error,
      pb.LogLevel.FATAL => LogLevel.fatal,
      _ => LogLevel.debug,
    };

    return LogEntity(level: level, time: message.time.toDateTime(), message: message.message);
  }

  static LogEntity parseSingbox(String log) {
    log = log.strip();
    DateTime? time;
    if (log.length > 25) {
      time = DateTime.tryParse(log.substring(6, 25));
    }
    if (time != null) {
      log = log.substring(26);
    }
    final level = LogLevel.values.firstOrNullWhere((e) {
      if (log.startsWith(e.name.toUpperCase())) {
        log = log.removePrefix(e.name.toUpperCase());
        return true;
      }
      return false;
    });
    return LogEntity(level: level, time: time, message: log.trim());
  }
}
