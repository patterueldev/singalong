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

  Future<APISongDetails> loadSongDetails(
      APILoadSongDetailsParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.songDetails,
      queryParameters: parameters.toJson(),
      method: HttpMethod.GET,
    );
    return APISongDetails.fromJson(result.objectData());
  }

  Future<APISongDetails> updateSongDetails(
      APIUpdateSongParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.songDetails,
      payload: parameters.toJson(),
      method: HttpMethod.PATCH,
    );
    return APISongDetails.fromJson(result.objectData());
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

  Future<String> newRoomID() async {
    final result = await apiClient.request(
      path: APIPath.adminGenerateRoomID,
      method: HttpMethod.GET,
    );
    return result.stringData();
  }

  Future<APIRoom> createRoom(APICreateRoomParameters parameters) async {
    final result = await apiClient.request(
      path: APIPath.adminCreateRoom,
      method: HttpMethod.POST,
      payload: parameters.toJson(),
    );
    return APIRoom.fromJson(result.objectData());
  }
}
