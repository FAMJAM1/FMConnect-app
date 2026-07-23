import 'dart:async';

import 'package:dartx/dartx.dart';

import 'package:hiddify/core/haptic/haptic_service.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/preferences/preferences_provider.dart';
import 'package:hiddify/core/utils/preferences_utils.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/data/offline_proxy_parser.dart';
import 'package:hiddify/features/proxy/data/proxy_data_providers.dart';
import 'package:hiddify/features/proxy/data/proxy_preferences.dart';
import 'package:hiddify/features/proxy/model/proxy_failure.dart';
import 'package:hiddify/hiddifycore/generated/v2/hcore/hcore.pb.dart';

import 'package:hiddify/utils/riverpod_utils.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'proxies_overview_notifier.g.dart';

enum ProxiesSort {
  unsorted,
  name,
  delay,
  usage;

  String present(TranslationsEn t) => switch (this) {
    ProxiesSort.unsorted => t.pages.proxies.sortOptions.unsorted,
    ProxiesSort.name => t.pages.proxies.sortOptions.name,
    ProxiesSort.delay => t.pages.proxies.sortOptions.delay,
    ProxiesSort.usage => t.pages.proxies.sortOptions.usage,
  };
}

@Riverpod(keepAlive: true)
class ProxiesSortNotifier extends _$ProxiesSortNotifier with AppLogger {
  late final _pref = PreferencesEntry(
    preferences: ref.watch(sharedPreferencesProvider).requireValue,
    key: "proxies_sort_mode",
    defaultValue: ProxiesSort.delay,
    mapFrom: ProxiesSort.values.byName,
    mapTo: (value) => value.name,
  );

  @override
  ProxiesSort build() {
    final sortBy = _pref.read();
    loggy.info("sort proxies by: [${sortBy.name}]");
    return sortBy;
  }

  Future<void> update(ProxiesSort value) {
    state = value;
    return _pref.write(value);
  }
}

@riverpod
class ProxiesOverviewNotifier extends _$ProxiesOverviewNotifier with AppLogger {
  @override
  Stream<OutboundGroup?> build() {
    ref.disposeDelay(const Duration(seconds: 15));
    final serviceRunning = ref.watch(serviceRunningProvider);
    if (!serviceRunning) {
      return _watchOffline();
    }
    final sortBy = ref.watch(proxiesSortNotifierProvider);
    // yield* ref
    //     .watch(proxyRepositoryProvider)
    //     .watchProxies()
    //     .throttleTime(
    //       const Duration(milliseconds: 100),
    //       leading: false,
    //       trailing: true,
    //     )
    //     .map(
    //       (event) => event.getOrElse(
    //         (err) {
    //           loggy.warning("error receiving proxies", err);
    //           throw err;
    //         },
    //       ),
    //     )
    //     .asyncMap((proxies) async => _sortOutbounds(proxies, sortBy));
    return ref
        .watch(proxyRepositoryProvider)
        .watchProxies()
        .map(
          (event) => event.getOrElse((err) {
            loggy.warning("error receiving proxies", err);
            throw err;
          }),
        )
        .asyncMap((proxies) async => await _sortOutbounds(proxies, sortBy));
  }

  /// Fallback used when the core isn't running: reads the active profile's
  /// saved config file directly instead of streaming from a live core, so
  /// the server list can still be browsed (no ping/delay data available).
  Stream<OutboundGroup?> _watchOffline() async* {
    final activeProfile = await ref.watch(activeProfileProvider.future);
    if (activeProfile == null) {
      throw const ServiceNotRunning();
    }
    final configFile = ref.watch(profilePathResolverProvider).file(activeProfile.id);
    final preferredTag = ref.watch(proxyPreferencesProvider).read(activeProfile.id);
    final offline = await parseOfflineProxyGroup(
      configFile,
      preferredTag: preferredTag.isEmpty ? null : preferredTag,
    );
    if (offline == null) {
      throw const ServiceNotRunning();
    }
    yield offline.group;
  }

  // Future<List<OutboundGroup>> _sortOutbounds(
  //   List<OutboundGroup> proxies,
  //   ProxiesSort sortBy,
  // ) async {
  //   final groupWithSelected = {
  //     for (final o in proxies) o.tag: o.selected,
  //   };
  //   final sortedProxies = <OutboundGroup>[];
  //   for (final group in proxies) {
  //     final sortedItems = switch (sortBy) {
  //       ProxiesSort.name => group.items.sortedWith((a, b) {
  //           if (a.isGroup && !b.isGroup) return -1;
  //           if (!a.isGroup && b.isGroup) return 1;
  //           return a.tag.compareTo(b.tag);
  //         }),
  //       ProxiesSort.delay => group.items.sortedWith((a, b) {
  //           if (a.isGroup && !b.isGroup) return -1;
  //           if (!a.isGroup && b.isGroup) return 1;

  //           final ai = a.urlTestDelay;
  //           final bi = b.urlTestDelay;
  //           if (ai == 0 && bi == 0) return -1;
  //           if (ai == 0 && bi > 0) return 1;
  //           if (ai > 0 && bi == 0) return -1;
  //           return ai.compareTo(bi);
  //         }),
  //       ProxiesSort.unsorted => group.items,
  //     };
  //     final items = <OutboundInfo>[];
  //     for (final item in sortedItems) {
  //       // if (groupWithSelected.keys.contains(item.tag)) {
  //       //   items.add(item.copyWith(selectedTag: groupWithSelected[item.tag]));
  //       // } else {
  //       items.add(item);
  //       // }
  //     }
  //     group.items.clear();
  //     group.items.addAll(items);
  //     sortedProxies.add(group);
  //   }
  //   return sortedProxies;
  // }

  Future<OutboundGroup?> _sortOutbounds(OutboundGroup? proxies, ProxiesSort sortBy) async {
    if (proxies == null) return null;

    final sortedItems = switch (sortBy) {
      ProxiesSort.name => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;
        return a.tag.compareTo(b.tag);
      }),
      ProxiesSort.delay => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;

        final ai = a.urlTestDelay;
        final bi = b.urlTestDelay;
        if (ai == 0 && bi == 0) return -1;
        if (ai == 0 && bi > 0) return 1;
        if (ai > 0 && bi == 0) return -1;
        return ai.compareTo(bi);
      }),
      ProxiesSort.unsorted => proxies.items,
      ProxiesSort.usage => proxies.items.sortedWith((a, b) {
        if (a.isGroup && !b.isGroup) return -1;
        if (!a.isGroup && b.isGroup) return 1;
        return (b.upload + b.download).compareTo(a.upload + a.download);
      }),
    };
    final items = <OutboundInfo>[];
    for (final item in sortedItems) {
      // if (groupWithSelected.keys.contains(item.tag)) {
      //   items.add(item.copyWith(selectedTag: groupWithSelected[item.tag]));
      // } else {
      items.add(item);
      // }
    }
    proxies.items.clear();
    proxies.items.addAll(items);
    return proxies;
  }

  // Future<void> changeProxy(String groupTag, String outboundTag) async {
  //   loggy.debug(
  //     "changing proxy, group: [$groupTag] - outbound: [$outboundTag]",
  //   );
  //   if (state case AsyncData(value: final outbounds)) {
  //     await ref.read(hapticServiceProvider.notifier).lightImpact();
  //     await ref.read(proxyRepositoryProvider).selectProxy(groupTag, outboundTag).getOrElse((err) {
  //       loggy.warning("error selecting outbound", err);
  //       throw err;
  //     }).run();
  //     final outboundg = outbounds.where((e) => e.tag == groupTag).firstOrNull;
  //     if (outboundg != null) {
  //       final newselected = outboundg.items.where((e) => e.tag == outboundTag).firstOrNull;
  //       if (newselected != null) {
  //         newselected.isSelected = true;
  //         outboundg.selected = newselected;
  //       }
  //     }
  //     state = AsyncData(
  //       [...outbounds],
  //     ).copyWithPrevious(state);
  //   }
  // }

  Future<void> changeProxy(String groupTag, String outboundTag) async {
    loggy.debug("changing proxy, group: [$groupTag] - outbound: [$outboundTag]");
    if (!state.hasValue) return;
    final outbounds = state.value!;
    await ref.read(hapticServiceProvider.notifier).lightImpact();

    if (ref.read(serviceRunningProvider)) {
      await ref.read(proxyRepositoryProvider).selectProxy(groupTag, outboundTag).getOrElse((err) {
        loggy.warning("error selecting outbound", err);
        throw err;
      }).run();
    } else {
      // No core running: just remember the pick, applied once the user
      // actually connects (see ConnectionNotifier).
      final activeProfile = await ref.read(activeProfileProvider.future);
      if (activeProfile != null) {
        await ref.read(proxyPreferencesProvider).write(activeProfile.id, outboundTag);
      }
    }

    for (final item in outbounds.items) {
      item.isSelected = item.tag == outboundTag;
    }
    outbounds.selected = outboundTag;
    state = AsyncValue.data(outbounds);
  }

  Future<void> urlTest(String groupTag, {OfflinePingMethod method = OfflinePingMethod.tcp}) async {
    loggy.debug("testing group: [$groupTag]");
    if (state case AsyncData(value: final group)) {
      await ref.read(hapticServiceProvider.notifier).lightImpact();

      if (ref.read(serviceRunningProvider)) {
        await ref.read(proxyRepositoryProvider).urlTest(groupTag).getOrElse((err) {
          loggy.error("error testing group", err);
          throw err;
        }).run();
      } else if (group != null) {
        await _offlineUrlTest(group, method);
      }
    }
  }

  /// No core running: probe each server directly (TCP connect, optionally
  /// followed by a TLS handshake) instead of the live urlTest RPC.
  Future<void> _offlineUrlTest(OutboundGroup group, OfflinePingMethod method) async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    if (activeProfile == null) return;
    final configFile = ref.read(profilePathResolverProvider).file(activeProfile.id);
    final addresses = await parseOfflineServerAddresses(configFile);

    await Future.wait(
      group.items.map((item) async {
        final address = addresses[item.tag];
        if (address == null) return;
        item.urlTestDelay = switch (method) {
          OfflinePingMethod.tcp => await measureTcpLatency(address.host, address.port),
          OfflinePingMethod.tls when address.useTls => await measureTlsHandshakeLatency(
            address.host,
            address.port,
          ),
          OfflinePingMethod.tls => await measureTcpLatency(address.host, address.port),
        };
      }),
    );
    state = AsyncValue.data(group);
  }
}
