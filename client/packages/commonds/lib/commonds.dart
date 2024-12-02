library commonds;

import 'dart:async';

import 'package:common/common.dart';
import 'package:encrypt_shared_preferences/provider.dart';
import 'package:faker_dart/faker_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:singalong_api_client/singalong_api_client.dart';
import 'package:uuid/uuid.dart';

part 'connect/connect_repositoryds.dart';
part 'persistence/persistenceds.dart';
part 'converters/reserved_song_item.dart';
part 'converters/song_details.dart';
part 'participant/user_participant_repositoryds.dart';

class CommonProvider {
  final providers = MultiProvider(providers: [
    // Provider<PersistenceRepository>.value(
    //     value: PersistenceRepositoryDS(encryptionKey: "1234567890123456")),
    ProxyProvider<SingalongConfiguration, PersistenceRepository>(
      update: (context, config, previous) => PersistenceRepositoryDS(
        encryptionKey: config.persistenceStorageKey,
      ),
    ),
    Provider<ConnectRepository>(
      create: (context) => ConnectRepositoryDS(
        api: context.read(),
        socket: context.read(),
        sessionManager: context.read(),
        persistenceRepository: context.read(),
      ),
    ),
    Provider<UserParticipantSocketRepository>(
      create: (context) => UserParticipantSocketRepositoryDS(
        socket: context.read(),
      ),
    ),
  ]);
}
