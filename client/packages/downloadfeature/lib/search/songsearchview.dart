part of '../downloadfeature.dart';

class DownloadableSongSearchView extends StatefulWidget {
  DownloadableSongSearchView({super.key}) : super();

  @override
  State<StatefulWidget> createState() => _DownloadableSongSearchViewState();
}

class _DownloadableSongSearchViewState
    extends State<DownloadableSongSearchView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<DownloadableSong> _songs = []; // Replace with your song model
  List<DownloadableSong> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    // Initialize your song list here
    _songs = getSongs(); // Replace with your method to get songs
    _filteredSongs = _songs;
  }

  void _filterSongs(String query) {
    final filtered = _songs.where((song) {
      final titleLower = song.title.toLowerCase();
      final artistLower = song.artist.toLowerCase();
      final searchLower = query.toLowerCase();

      return titleLower.contains(searchLower) ||
          artistLower.contains(searchLower);
    }).toList();

    setState(() {
      _filteredSongs = filtered;
    });
  }

  @override
  Widget build(BuildContext context) => Consumer<DownloadableSearchViewModel>(
        builder: (context, viewModel, _) => Scaffold(
          appBar: AppBar(
            title: ValueListenableBuilder(
              valueListenable: viewModel.searchFieldStatusNotifier,
              builder: (context, status, child) => status.isSearching()
                  ? TextField(
                      autocorrect: false,
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: viewModel.updateSearchQuery,
                      decoration: InputDecoration(
                        hintText: "search something",
                        border: InputBorder.none,
                        fillColor: Colors.grey,
                      ),
                      style: const TextStyle(color: Colors.black),
                    )
                  : Text("Search"),
            ),
            actions: [
              ValueListenableBuilder(
                valueListenable: viewModel.searchFieldStatusNotifier,
                builder: (context, status, child) => IconButton(
                  icon: status.isSearching()
                      ? const Icon(Icons.close)
                      : const Icon(Icons.search),
                  onPressed: () => {
                    if (status.isSearching()) _searchController.clear(),
                    viewModel.toggleSearch(),
                  },
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _filterSongs,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = _filteredSongs[index];
                    return ListTile(
                      leading: Image.network(
                          song.thumbnailUrl), // Replace with your thumbnail URL
                      title: Text(song.title),
                      subtitle: Text('${song.artist} • ${song.duration}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}

// Replace with your song model
class DownloadableSong {
  final String title;
  final String artist;
  final String thumbnailUrl;
  final String duration;

  DownloadableSong({
    required this.title,
    required this.artist,
    required this.thumbnailUrl,
    required this.duration,
  });
}

// Replace with your method to get songs
List<DownloadableSong> getSongs() {
  return [
    DownloadableSong(
      title: 'Song 1',
      artist: 'Artist 1',
      thumbnailUrl: 'https://example.com/thumbnail1.jpg',
      duration: '3:45',
    ),
    DownloadableSong(
      title: 'Song 2',
      artist: 'Artist 2',
      thumbnailUrl: 'https://example.com/thumbnail2.jpg',
      duration: '4:20',
    ),
    // Add more songs here
  ];
}
