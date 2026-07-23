import 'package:flutter/material.dart';

class ConnectionButtonTheme extends ThemeExtension<ConnectionButtonTheme> {
  const ConnectionButtonTheme({this.idleColor, this.connectedColor, this.backgroundColor, this.ringBorder = false});

  final Color? idleColor;
  final Color? connectedColor;

  /// Disc behind the connect icon. Defaults to white (see [light]) - fine on
  /// a light/dark Material theme, but a stark white disc clashes on
  /// [console]'s near-black surfaces, so that variant swaps it for a dark
  /// surface color instead.
  final Color? backgroundColor;

  /// Whether to outline the disc with the current state color ([idleColor]/
  /// [connectedColor]). Off by default (the white disc already reads clearly
  /// against any background); [console] turns it on since its dark disc
  /// otherwise has no visible edge against the equally-dark scaffold.
  final bool ringBorder;

  static const ConnectionButtonTheme light = ConnectionButtonTheme(
    idleColor: Color(0xFF0091FF),
    connectedColor: Color(0xFF44a334),
    backgroundColor: Colors.white,
  );

  static const ConnectionButtonTheme console = ConnectionButtonTheme(
    idleColor: Color(0xFF00D9FF),
    connectedColor: Color(0xFF00F0A0),
    backgroundColor: Color(0xFF111119),
    ringBorder: true,
  );

  @override
  ThemeExtension<ConnectionButtonTheme> copyWith({
    Color? idleColor,
    Color? connectedColor,
    Color? backgroundColor,
    bool? ringBorder,
  }) => ConnectionButtonTheme(
    idleColor: idleColor ?? this.idleColor,
    connectedColor: connectedColor ?? this.connectedColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    ringBorder: ringBorder ?? this.ringBorder,
  );

  @override
  ThemeExtension<ConnectionButtonTheme> lerp(covariant ThemeExtension<ConnectionButtonTheme>? other, double t) {
    if (other is! ConnectionButtonTheme) {
      return this;
    }
    return ConnectionButtonTheme(
      idleColor: Color.lerp(idleColor, other.idleColor, t),
      connectedColor: Color.lerp(connectedColor, other.connectedColor, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      ringBorder: t < 0.5 ? ringBorder : other.ringBorder,
    );
  }
}

/// Status colors with no Material 3 [ColorScheme] slot of their own
/// (success/warning) - only populated for themes that define an explicit
/// palette for them (currently just [console]); elsewhere falls back to the
/// hardcoded greens/ambers already scattered across the app.
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({this.success, this.warning});

  final Color? success;
  final Color? warning;

  static const StatusColors console = StatusColors(success: Color(0xFF00F0A0), warning: Color(0xFFF59E0B));

  @override
  ThemeExtension<StatusColors> copyWith({Color? success, Color? warning}) =>
      StatusColors(success: success ?? this.success, warning: warning ?? this.warning);

  @override
  ThemeExtension<StatusColors> lerp(covariant ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    return StatusColors(
      success: Color.lerp(success, other.success, t),
      warning: Color.lerp(warning, other.warning, t),
    );
  }
}
