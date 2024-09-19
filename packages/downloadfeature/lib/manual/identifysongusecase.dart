part of '../downloadfeature.dart';

abstract class IdentifySongUrlUseCase {
  TaskEither<GenericException, IdentifiedSongDetails> call(String url);
}

class DefaultIdentifySongUrlUseCase implements IdentifySongUrlUseCase {
  @override
  TaskEither<GenericException, IdentifiedSongDetails> call(String url) =>
      TaskEither.tryCatch(() async {
        // validate if the url is empty
        if (url.isEmpty) {
          throw DownloadException.emptyUrl();
        }

        if (!isValidUrl(url)) {
          throw DownloadException.invalidUrl();
        }

        await Future.delayed(const Duration(seconds: 2));
        return IdentifiedSongDetails(
          id: '123',
          source: 'ourtube',
          imageUrl:
              'https://i.scdn.co/image/ab67616d0000b273dbb7fed72ad0252a51f386f2',
          songTitle: 'Fuwa Fuwa Time',
          songArtist: 'Houkago Tea Time',
          songLanguage: 'Japanese',
          isOffVocal: false,
          videoHasLyrics: false,
          songLyrics: _randomLyrics,
        );
      }, (e, s) {
        if (e is GenericException) {
          return e;
        }
        return GenericException.unhandled(e);
      });

  bool isValidUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    return uri != null && (uri.hasScheme && uri.hasAuthority);
  }
}

String _randomLyrics = """
キミを見てるといつもハートDOKI☆DOKI
揺れる思いはマシュマロみたいにふわ☆ふわ
いつもがんばるキミの横顔
ずっと見てても気づかないよね
夢の中なら二人の距離縮められるのにな
あぁカミサマお願い
二人だけのDream Timeください☆
お気に入りのうさちゃん抱いて今夜もオヤスミ
ふわふわタイム ふわふわタイム ふわふわタイム
ふとした仕草に今日もハートZUKI★ZUKI
さりげな笑顔を深読みしぎてover heat!
いつか目にしたキミのマジ顔
瞳閉じても浮かんでくるよ
夢でいいから二人だけのSweet time欲しいの
あぁカミサマどうして
好きになるほどDream nightせつないの
とっておきのくまちゃん出したし今夜は大丈夫かな？
もすこし勇気ふるって
自然に話せば
何かが変わるのかな？
そんな気するけど
だけどそれが一番難しいのよ
話のきっかけとかどうしよ
てか段取り考えてる時点で全然自然じゃないよね
あぁもういいや寝ちゃお寝ちゃお寝ちゃお―っ！
あぁカミサマお願い
一度だけのMiracle Timeください！
もしすんあり話せればその後は⋯どうにかなるよね
ふわふわタイム ふわふわタイム ふわふわタイム
""";
