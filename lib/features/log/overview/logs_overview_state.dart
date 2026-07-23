import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hiddify/features/log/model/log_entity.dart';
import 'package:hiddify/features/log/model/log_level.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logs_overview_state.freezed.dart';

enum LogSource { app, core }

@freezed
class LogsOverviewState with _$LogsOverviewState {
  const LogsOverviewState._();

  const factory LogsOverviewState({
    @Default(AsyncLoading()) AsyncValue<List<LogEntity>> logs,
    @Default(false) bool paused,
    @Default("") String filter,
    @Default(LogSource.core) LogSource source,
    LogLevel? levelFilter,
  }) = _LogsOverviewState;
}
