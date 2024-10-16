library downloadfeature_ds;

import 'dart:convert';

import 'package:downloadfeature/downloadfeature.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';

part 'downloadfeatureds_provider.dart';

class DefaultSongIdentifierRepository implements SongIdentifierRepository {
  final Client client;
  final DownloadFeatureDSConfiguration configuration;

  const DefaultSongIdentifierRepository({
    required this.client,
    required this.configuration,
  });

  @override
  Future<IdentifiedSongDetails> identifySongUrl(String url) async {
    try {
      final base = configuration.baseUrl;
      final raw = "$base/songs/identify";
      final postUri = Uri.parse(raw);
      final Map<String, String> params = {
        'url': url,
      };
      debugPrint("Request: POST $raw");
      final response = await client.post(postUri,
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode(params));
      debugPrint("Response: ${response.body}");
      final decoded = json.decoder.convert(response.body);
      final data = decoded["data"];
      final identified = IdentifiedSongDetails(
        id: data['id'],
        source: data['source'],
        imageUrl: data['imageUrl'],
        songTitle: data['songTitle'],
        songArtist: data['songArtist'],
        songLanguage: data['songLanguage'],
        isOffVocal: data['isOffVocal'],
        videoHasLyrics: data['videoHasLyrics'],
        songLyrics: data['songLyrics'],
      );
      return identified;
    } on ClientException catch (e) {
      debugPrint("ClientException: $e");
      debugPrint("message: ${e.message}");
      debugPrint("uri: ${e.uri}");
      rethrow;
    } catch (e, st) {
      debugPrint("Error: $e");
      rethrow;
    }
  }

  @override
  Future<void> saveSong(IdentifiedSongDetails details,
      {required bool reserve}) {
    // TODO: implement downloadSong
    throw UnimplementedError();
  }
}

class DownloadSongParameters {}

class DownloadFeatureDSConfiguration {
  final String baseUrl;

  const DownloadFeatureDSConfiguration({
    required this.baseUrl,
  });
}
