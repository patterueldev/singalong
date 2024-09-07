part of 'songbookfeature.dart';

class SongBookView extends StatefulWidget {
  const SongBookView({
    super.key,
    required this.viewModel,
  });

  final SongBookViewModel viewModel;
  @override
  State<SongBookView> createState() => _SongBookViewState();
}

class SongItem {
  final String title;
  final String artist;
  final String imageURL;
  final bool
      alreadyPlayed; // doesn't mean it can't be played again, just for indication

  const SongItem({
    required this.title,
    required this.artist,
    required this.imageURL,
    required this.alreadyPlayed,
  });
}

abstract class SongBookViewModel {
  ValueNotifier<List<SongItem>> get songListNotifier;

  void fetchSongs();
}

class _SongBookViewState extends State<SongBookView> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.fetchSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Song Book'),
      ),
      body: ValueListenableBuilder<List<SongItem>>(
        valueListenable: widget.viewModel.songListNotifier,
        builder: (context, songList, child) {
          if (songList.isEmpty) {
            return Center(child: CircularProgressIndicator());
          } else {
            return ListView.builder(
              itemCount: songList.length,
              itemBuilder: (context, index) {
                final song = songList[index];
                return ListTile(
                  leading: Image.network(song.imageURL),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  trailing: song.alreadyPlayed
                      ? Icon(Icons.check, color: Colors.green)
                      : null,
                );
              },
            );
          }
        },
      ),
    );
  }
}

class SongBookViewState {
  const SongBookViewState();
}

class Initial extends SongBookViewState {
  const Initial();
}

class Loading extends SongBookViewState {
  const Loading();
}

class Loaded extends SongBookViewState {
  const Loaded();
}

class Failure extends SongBookViewState {
  final String error;
  const Failure(this.error);
}
