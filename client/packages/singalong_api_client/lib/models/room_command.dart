part of '../singalong_api_client.dart';

@JsonSerializable()
class RoomCommand {
  final RoomCommandType type;
  final dynamic data;

  RoomCommand(this.type, this.data);

  factory RoomCommand.fromJson(Map<String, dynamic> json) =>
      _$RoomCommandFromJson(json);
  Map<String, dynamic> toJson() => _$RoomCommandToJson(this);

  String toJsonString() => jsonEncode(toJson());

  factory RoomCommand.skipSong(bool completed) =>
      RoomCommand(RoomCommandType.skipSong, completed);
  factory RoomCommand.togglePlayPause(bool isPlaying) =>
      RoomCommand(RoomCommandType.togglePlayPause, isPlaying);
  factory RoomCommand.adjustVolume(double volume) =>
      RoomCommand(RoomCommandType.adjustVolume, volume);
  factory RoomCommand.durationUpdate({required int durationInMilliseconds}) =>
      RoomCommand(RoomCommandType.durationUpdate, durationInMilliseconds);
  factory RoomCommand.seekDurationFromControl(
          {required int durationInSeconds}) =>
      RoomCommand(RoomCommandType.seekDuration, durationInSeconds);
}
