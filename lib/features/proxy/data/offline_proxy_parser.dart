import 'dart:convert';
import 'dart:io';

import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

typedef ServerAddress = ({String host, int port, bool useTls, String sni});

/// How to probe a server's reachability/latency without a running core.
enum OfflinePingMethod {
  /// Raw TCP connect - fast, works for any server.
  tcp,

  /// Completes a TLS handshake on top of the TCP connect - closer to real
  /// usability for the (common) TLS-based protocols, falls back to [tcp]
  /// for servers that don't use TLS.
  tls,
}

/// Result of parsing a profile's saved sing-box config file without a
/// running core: the selector group's tag (needed later to call
/// `selectOutbound`) plus a synthetic [OutboundGroup] for display.
class OfflineProxyGroup {
  const OfflineProxyGroup({required this.groupTag, required this.group});

  final String groupTag;
  final OutboundGroup group;
}

/// Reads a profile's already-generated sing-box config JSON (written by the
/// core when the profile was added/updated) and builds a synthetic
/// [OutboundGroup] from its `selector` outbound's `outbounds` list, so the
/// server list can be shown without an active connection. No ping/delay
/// data is available this way — that only exists once the core is running.
Future<OfflineProxyGroup?> parseOfflineProxyGroup(File configFile, {String? preferredTag}) async {
  if (!configFile.existsSync()) return null;

  final Map<String, dynamic> config;
  try {
    final content = await configFile.readAsString();
    config = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }

  final outbounds = config['outbounds'];
  if (outbounds is! List) return null;
  final selectorOutboundMaps = outbounds.whereType<Map<String, dynamic>>().where((o) => o['type'] == 'selector');

  // A config can contain more than one `type: selector` outbound (e.g.
  // per-rule groups) - the one actually driving traffic is whichever tag
  // `route.final` points at (see fmconnect-core's OutboundSelectTag/
  // OutboundMainDetour), not necessarily the first one to appear in the
  // `outbounds` array. Falls back to "first selector" if that field is
  // missing/doesn't resolve, rather than returning nothing.
  final routeFinal = (config['route'] as Map<String, dynamic>?)?['final'] as String?;
  Map<String, dynamic> fallback() {
    for (final o in selectorOutboundMaps) {
      return o;
    }
    return const {};
  }

  final selector = selectorOutboundMaps.firstWhere((o) => o['tag'] == routeFinal, orElse: fallback);
  final selectorTag = selector['tag'] as String?;
  final selectorOutbounds = selector['outbounds'];
  if (selectorTag == null || selectorOutbounds is! List) return null;

  // The config file's own `default` is only updated once the core actually
  // runs and calls selectOutbound - while offline we never rewrite the
  // file, so a preference saved from the offline picker (see
  // ProxyPreferences) takes priority when present, or the selector list
  // wouldn't reflect the user's last pick at all.
  final currentDefault = (preferredTag != null && selectorOutbounds.contains(preferredTag))
      ? preferredTag
      : selector['default'] as String?;

  final items = selectorOutbounds.whereType<String>().map(
    (tag) => OutboundInfo(
      tag: tag,
      tagDisplay: tag,
      isGroup: false,
      isVisible: true,
      isSelected: tag == currentDefault,
    ),
  );

  return OfflineProxyGroup(
    groupTag: selectorTag,
    group: OutboundGroup(
      tag: selectorTag,
      type: 'selector',
      selected: currentDefault ?? '',
      selectable: true,
      items: items,
    ),
  );
}

/// Reads the connection target (`server`/`server_port`) of every leaf
/// outbound in a profile's saved config, keyed by tag. Group outbounds
/// (selector/urltest) have neither field and are naturally excluded - there
/// is no single server to ping for those.
Future<Map<String, ServerAddress>> parseOfflineServerAddresses(File configFile) async {
  if (!configFile.existsSync()) return const {};

  final Map<String, dynamic> config;
  try {
    final content = await configFile.readAsString();
    config = jsonDecode(content) as Map<String, dynamic>;
  } catch (_) {
    return const {};
  }

  final outbounds = config['outbounds'];
  if (outbounds is! List) return const {};

  final addresses = <String, ServerAddress>{};
  for (final outbound in outbounds.whereType<Map<String, dynamic>>()) {
    final tag = outbound['tag'] as String?;
    final host = outbound['server'] as String?;
    final port = outbound['server_port'];
    if (tag != null && host != null && port is int) {
      final tls = outbound['tls'];
      final useTls = tls is Map && tls['enabled'] == true;
      final sni = (useTls ? tls['server_name'] as String? : null) ?? host;
      addresses[tag] = (host: host, port: port, useTls: useTls, sni: sni);
    }
  }
  return addresses;
}

/// Sentinel matching the core's own convention (see proxy_tile.dart:
/// `urlTestDelay > 65000` renders as "×") for an unreachable/timed-out
/// server.
const offlinePingTimeoutDelay = 65535;

/// Measures raw TCP connect latency to a server - the closest thing to a
/// "ping" available without a running core (no VPN protocol handshake, just
/// reachability + round-trip time to open the socket).
Future<int> measureTcpLatency(String host, int port, {Duration timeout = const Duration(seconds: 3)}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final socket = await Socket.connect(host, port, timeout: timeout);
    stopwatch.stop();
    socket.destroy();
    return stopwatch.elapsedMilliseconds;
  } catch (_) {
    return offlinePingTimeoutDelay;
  }
}

/// Measures TCP connect + full TLS handshake latency to a server (SNI is
/// the connection host itself, which matches `tls.server_name` in the
/// overwhelming majority of real configs). Closer to a real "can I actually
/// talk to this server" test than [measureTcpLatency] alone, still without
/// needing the specific VPN protocol on top. Server certificate isn't
/// validated for trust here - this only times reachability, the real core
/// still validates certificates when actually connecting.
Future<int> measureTlsHandshakeLatency(
  String host,
  int port, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final stopwatch = Stopwatch()..start();
  try {
    final socket = await SecureSocket.connect(
      host,
      port,
      timeout: timeout,
      onBadCertificate: (_) => true,
    );
    stopwatch.stop();
    socket.destroy();
    return stopwatch.elapsedMilliseconds;
  } catch (_) {
    return offlinePingTimeoutDelay;
  }
}
