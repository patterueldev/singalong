import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

enum FinishState {
  none,
  authenticated,
  unauthenticated,
}

abstract class SplashScreenViewModel extends ChangeNotifier {
  ValueNotifier<FinishState> get didFinishStateNotifier;

  String? get username;
  String? get roomId;

  void load();
}

class DefaultSplashScreenViewModel extends SplashScreenViewModel {
  final PersistenceService persistenceService;

  DefaultSplashScreenViewModel({
    required this.persistenceService,
  });

  @override
  final ValueNotifier<FinishState> didFinishStateNotifier =
      ValueNotifier(FinishState.none);

  String? username;
  String? roomId;

  @override
  void load() async {
    try {
      debugPrint("Attempting to load username and room id");
      username = await persistenceService.getUsername();
      roomId = await persistenceService.getRoomId();
    } catch (e) {
      debugPrint("Error while loading: $e");
    }
    await Future.delayed(const Duration(seconds: 2));
    didFinishStateNotifier.value = FinishState.unauthenticated;
  }
}
