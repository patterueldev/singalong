// ignore_for_file: avoid_web_libraries_in_flutter
// This is a web-specific file and should not have any Flutter-specific code.

import 'dart:convert';

import 'package:common/common.dart';
import 'package:controller/web/approute.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';

import 'dart:html' as html;
import 'splash_viewmodel.dart';

class WebSplashScreenViewModel extends SplashScreenViewModel {
  final ConnectRepository connectRepository;
  final PersistenceRepository
      persistenceService; // Might need this when restoring authentication
  final SingalongConfiguration configuration;

  WebSplashScreenViewModel({
    required this.connectRepository,
    required this.persistenceService,
    required this.configuration,
  });

  @override
  final ValueNotifier<SplashState> didFinishStateNotifier =
      ValueNotifier(SplashState.idle());

  Future<void> setupFromTunnel() async {
    try {
      // try to get json from `<defaultHost>/tunnel.json`
      final location = html.window.location;
      final components = location.host.split('.');
      // host contains a port number; we need to remove it
      final protocol = location.protocol;
      final host = location.hostname ?? components[0];
      if (host.contains("local")) return;
      final port = location.port.isNotEmpty ? ":${location.port}" : "";
      final epoc = DateTime.now().millisecondsSinceEpoch;
      final raw = "$protocol//$host$port/tunnel.json?q=$epoc";
      debugPrint("Trying to load json from: $raw");
      final response = await html.HttpRequest.request(raw);
      final json = response.response;
      debugPrint("Got json: $json"); // should be like
      final data = jsonDecode(json);
      final isTunnel = data['is_tunnel'];
      if (isTunnel) {
        debugPrint("Tunnel is enabled");
        final apiTunnelUrl = data['api_tunnel_url'];
        final socketStorageUrl = data['socket_storage_tunnel_url'];

        final apiUri = Uri.parse(apiTunnelUrl);
        await persistenceService.saveString(
            PersistenceKey.customApiProtocol, apiUri.scheme);
        await persistenceService.saveString(
            PersistenceKey.customApiHost, apiUri.host);
        await persistenceService.saveInt(
            PersistenceKey.customApiPort, apiUri.port);

        final socketStorageUri = Uri.parse(socketStorageUrl);
        await persistenceService.saveString(
            PersistenceKey.customSocketProtocol, socketStorageUri.scheme);
        await persistenceService.saveString(
            PersistenceKey.customSocketHost, socketStorageUri.host);
        await persistenceService.saveInt(
            PersistenceKey.customSocketPort, socketStorageUri.port);

        await persistenceService.saveString(
            PersistenceKey.customStorageProtocol, socketStorageUri.scheme);
        await persistenceService.saveString(
            PersistenceKey.customStorageHost, socketStorageUri.host);
        await persistenceService.saveInt(
            PersistenceKey.customStoragePort, socketStorageUri.port);

        debugPrint("Saved tunnel configuration");
        debugPrint("API: $apiUri");
        debugPrint("Socket/Storage: $socketStorageUri");
      }
    } catch (e) {
      debugPrint("Error while loading json: $e");
    }
  }

  @override
  void load() async {
    try {
      await setupFromTunnel();
      // will have to check if query contained custom configurations like these
      configuration.customProtocol =
          await persistenceService.getString(PersistenceKey.customApiProtocol);

      configuration.customApiHost =
          await persistenceService.getString(PersistenceKey.customApiHost);
      configuration.customApiPort =
          await persistenceService.getInt(PersistenceKey.customApiPort);
      configuration.customSocketHost =
          await persistenceService.getString(PersistenceKey.customSocketHost);
      configuration.customSocketPort =
          await persistenceService.getInt(PersistenceKey.customSocketPort);
      configuration.customStorageHost =
          await persistenceService.getString(PersistenceKey.customStorageHost);
      configuration.customStoragePort =
          await persistenceService.getInt(PersistenceKey.customStoragePort);

      // check current address from browser
      final uri = html.window.location.href;
      final path = html.window.location.pathname;
      debugPrint("Current address: $uri");
      debugPrint("Current path: $path");
      final route = AppRoute.fromPath(path!);
      if (route == AppRoute.sessionConnect) {
        // no need to check for authentication
        return;
      }
      final isAuthenticated = await connectRepository.checkAuthentication();
      if (isAuthenticated) {
        didFinishStateNotifier.value = SplashState.authenticated(null);
      } else {
        didFinishStateNotifier.value = SplashState.unauthenticated();
      }
    } catch (e) {
      debugPrint("Error while loading: $e");
    }
  }
}
