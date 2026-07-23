import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'proxy_preferences.g.dart';

/// Stores the user's preferred outbound (server) tag per profile, chosen
/// while browsing the offline (pre-connect) server list. Applied once the
/// user actually connects (see [ConnectionNotifier]).
class ProxyPreferences {
  ProxyPreferences(this._prefs);

  final SharedPreferences _prefs;

  String _key(String profileId) => "preferred-outbound-$profileId";

  String read(String profileId) => _prefs.getString(_key(profileId)) ?? "";

  Future<void> write(String profileId, String outboundTag) => _prefs.setString(_key(profileId), outboundTag);
}

@Riverpod(keepAlive: true)
ProxyPreferences proxyPreferences(Ref ref) {
  return ProxyPreferences(ref.watch(sharedPreferencesProvider).requireValue);
}
