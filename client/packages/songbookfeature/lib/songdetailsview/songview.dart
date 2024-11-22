part of '../songbookfeature.dart';

class SongView extends StatelessWidget {
  const SongView({
    super.key,
    required this.localizations,
  });

  final SongBookLocalizations localizations;

  @override
  Widget build(BuildContext context) => Consumer<SongViewModel>(
        builder: (context, viewModel, child) => Scaffold(
          body: ValueListenableBuilder(
            valueListenable: viewModel.stateNotifier,
            builder: (context, state, child) {
              switch (state.type) {
                case SongViewStateType.initial:
                case SongViewStateType.loading:
                  return const Center(child: CircularProgressIndicator());
                case SongViewStateType.loaded:
                  final loaded = state as SongDetailsLoaded;
                  return _buildLoaded(context, loaded.song);
                case SongViewStateType.failure:
                  final failure = state as SongDetailsFailure;
                  return Center(child: Text(failure.error));
              }
            },
          ),
        ),
      );

  Widget _buildLoaded(BuildContext context, SongDetails song) => Scaffold(
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
                        imageUrl: song.thumbnailURL.toString(),
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
