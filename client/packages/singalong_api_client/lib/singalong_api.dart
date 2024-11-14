part of 'singalong_api_client.dart';

class SingalongAPI {
  final APIClient apiClient;

  SingalongAPI({required this.apiClient});

  Future<APIConnectResponseData> connect(
      APIConnectParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.sessionConnect,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
      requireAuth: false,
    );
    return APIConnectResponseData.fromJson(result.objectData());
  }

  Future<APIConnectWithRoomResponseData> connectWithRoom(String roomId) async {
    final result = await apiClient.request(
      path: APIPath.adminConnectRoom,
      method: HttpMethod.POST,
      payload: {'roomId': roomId},
    );
    return APIConnectWithRoomResponseData.fromJson(result.objectData());
  }

  Future<String> check() async {
    final result = await apiClient.request(
      path: APIPath.sessionCheck,
      method: HttpMethod.GET,
    );
    return result.data as String;
  }

  Future<APIPaginatedSongs> loadSongs(APILoadSongsParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.songs,
      queryParameters: parameters.toJson(),
      method: HttpMethod.GET,
      payload: parameters.toJson(),
    );
    return APIPaginatedSongs.fromJson(result.objectData());
  }

  Future<void> reserveSong(APIReserveSongParameters parameters) async {
    await apiClient.request(
      path: APIPath.reserveSong,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
  }

  Future<APIIdentifiedSongDetails> identifySong(
      APIIdentifySongParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.identifySong,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
    return APIIdentifiedSongDetails.fromJson(result.objectData());
  }

  Future<APISaveSongResponseData> saveSong(
      APISaveSongParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.songs,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
    return APISaveSongResponseData.fromJson(result.objectData());
  }

  Future<List<APIDownloadableData>> searchDownloadables(
      APISearchDownloadablesParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.downloadable,
      queryParameters: parameters.toJson(),
      method: HttpMethod.GET,
    );
    return result
        .arrayData()
        .map((e) => APIDownloadableData.fromJson(e))
        .toList();
  }

  Future<APIPaginatedRoomList> loadRooms(
      APILoadRoomListParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.adminRooms,
      queryParameters: parameters.toJson(),
      method: HttpMethod.GET,
    );
    return APIPaginatedRoomList.fromJson(result.objectData());
  }

  Future<void> assignPlayerToRoom(String playerId, String roomId) async {
    await apiClient.request(
      path: APIPath.adminAssignRoom,
      method: HttpMethod.POST,
      payload: {'playerId': playerId, 'roomId': roomId},
    );
  }
}
