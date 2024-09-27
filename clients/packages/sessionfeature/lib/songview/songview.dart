part of '../sessionfeature.dart';

class SongView extends StatefulWidget {
  const SongView({
    super.key,
    required this.localizations,
  });

  @override
  State<SongView> createState() => _SongViewState();

  final SessionLocalizations localizations;
}

class _SongViewState extends State<SongView> {
  SessionLocalizations get localizations => widget.localizations;
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SongViewModel>().loadDetails();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Consumer<SongViewModel>(
          builder: (context, viewModel, child) {
            switch (viewModel.state.type) {
              case SongViewStateType.initial:
              case SongViewStateType.loading:
                return const Center(child: CircularProgressIndicator());
              case SongViewStateType.loaded:
                final loaded = viewModel.state as Loaded;
                return _buildLoaded(loaded.song);
              case SongViewStateType.failure:
                final failure = viewModel.state as Failure;
                return Center(child: Text(failure.error));
            }
          },
        ),
      );

  Widget _buildLoaded(SongModel song) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100.0,
                    height: 100.0,
                    decoration: BoxDecoration(
                      color: Colors.grey, // Set the background color to grey
                      borderRadius: BorderRadius.circular(
                          8.0), // Optional: Add border radius
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                          8.0), // Optional: Match border radius
                      child: CachedNetworkImage(
                        imageUrl: song.imageURL.toString(),
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note),
                        fit: BoxFit
                            .cover, // Ensure the image covers the container
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          song.artist,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                localizations.lyricsLabelText.localizedOf(context),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    song.lyrics ??
                        localizations.noLyricsText.localizedOf(context),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
