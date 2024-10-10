part of '../sessionfeature.dart';

abstract class SongViewModel extends ChangeNotifier {
  SongViewState get state;
  void loadDetails();
}

class DefaultSongViewModel extends SongViewModel {
  DefaultSongViewModel({required this.songId});

  final String songId;

  @override
  SongViewState state = SongViewState.initial();

  @override
  void loadDetails() async {
    state = SongViewState.loading();
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    state = SongViewState.loaded(
      SongModel(
        title: 'ふわふわタイム',
        artist: '放課後ティータイム',
        imageURL:
            'https://i.scdn.co/image/ab67616d0000b273dbb7fed72ad0252a51f386f2',
        currentPlaying: false,
        lyrics: _randomLyrics,
      ),
    );
    notifyListeners();
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
