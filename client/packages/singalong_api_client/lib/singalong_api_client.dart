library singalong_api_client;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:provider/provider.dart';
import 'package:core/core.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

part 'singalong_api_client.g.dart';
part 'api_path.dart';
part 'api_session_manager.dart';
part 'api_client.dart';
part 'singalong_api.dart';
part 'singalong_api_client_provider.dart';
part 'singalong_socket.dart';
part 'socket_events/socket_events.dart';
part 'models/generic_response.dart';
part 'models/connect_parameters.dart';
part 'models/connect_response.dart';
part 'models/reserved_song.dart';
part 'models/current_song.dart';
part 'models/song.dart';
part 'models/identified_song_details.dart';
part 'models/save_song_parameters.dart';
part 'models/save_song_response.dart';
part 'models/downloadable_item.dart';
part 'models/room.dart';
part 'models/connect_withroom_response.dart';
part 'models/player_item.dart';
part 'models/create_room_parameters.dart';
part 'models/song_details.dart';
part 'models/update_song_parameters.dart';
part 'models/user_participant.dart';
