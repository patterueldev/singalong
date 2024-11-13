part of '../adminfeature.dart';

abstract class PlayerManagerViewModel extends ChangeNotifier {
  ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);
  ValueNotifier<List<PlayerItem>> playersNotifier = ValueNotifier([]);
}

// TODO: It goes like this: The admin logs in, and they will see a 'real time' list of players (ideally only 1 player at a time, but who knows)
//      The admin selects a player to set up. If an active player is selected, they have the option make it idle again
//      Otherwise, the idle player can be set with an idle room as well. (or is it the other way around)
//      If we tie the real world/real life thing, then the player is inside a room, so the room is the one that is idle, not the player
//      In real life, a room is just a part of a building. But in this app, a room is just a session and can be created
//      But the idea remains that if a room exists, then a player should be inside of it. But in this app, a player can be assigned to a room. equivalent to one of the players being put inside a room
//      So the player is the one that is idle, not the room. The room is just a session that can be created and destroyed
class PlayerItem {
  final String id;
  final String name;
  final bool isIdle;

  PlayerItem({
    required this.id,
    required this.name,
    required this.isIdle,
  });
}
