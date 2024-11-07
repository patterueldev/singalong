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

  // TODO: Will do this through socket
  Future<void> nextSong() async {
    await apiClient.request(
      path: APIPath.next,
      method: HttpMethod.PATCH,
    );
  }
}
