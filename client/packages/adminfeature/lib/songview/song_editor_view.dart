part of '../adminfeature.dart';

class SongEditorView extends StatelessWidget {
  SongEditorView({
    super.key,
    required this.localizations,
    required this.coordinator,
  });

  final AdminLocalizations localizations;
  final AdminCoordinator coordinator;

  @override
  Widget build(BuildContext context) => Consumer<SongEditorViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            ValueListenableBuilder(
              valueListenable: viewModel.stateNotifier,
              builder: (context, state, child) {
                switch (state.type) {
                  case SongViewStateType.initial:
                  case SongViewStateType.loading:
                    return const Center(child: CircularProgressIndicator());
                  case SongViewStateType.loaded:
                    final loaded = state as Loaded;
                    return _buildLoaded(context, loaded);
                  case SongViewStateType.failure:
                    final failure = state as Failure;
                    return Center(child: Text(failure.error));
                }
              },
            ),

            // Loading Indicator
            ValueListenableBuilder(
              valueListenable: viewModel.isLoadingNotifier,
              builder: (context, isLoading, child) {
                if (isLoading) {
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            // Prompt (toast)
            ValueListenableBuilder(
              valueListenable: viewModel.promptNotifier,
              builder: (context, prompt, child) {
                if (prompt != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: prompt.message.localizedTextOf(context)),
                    );
                    viewModel.promptNotifier.value = null;
                  });
                }
                return const SizedBox.shrink();
              },
            ),

            // On Finished
            ValueListenableBuilder(
              valueListenable: viewModel.finishedSavingNotifier,
              builder: (context, finished, child) {
                if (finished) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(context).pop(true);
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      );

  Widget _buildLoaded(BuildContext context, Loaded state) {
    return ValueListenableBuilder(
      valueListenable: state.songNotifier,
      builder: (context, song, child) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxWidth: 800,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // Preview Button
                IconButton(
                  icon: const Icon(Icons.preview),
                  onPressed: () {
                    final url = Uri.parse(song.source);
                    coordinator.openURL(context, url);
                  },
                ),
                // Delete Button
                TextButton(
                  onPressed: () {
                    context.read<SongEditorViewModel>().deleteSong(song);
                  },
                  child: Text("Delete"),
                ),

                // Save Button
                ValueListenableBuilder(
                    valueListenable: state.songNotifier,
                    builder: (context, song, child) {
                      if (song.isCorrupted) {
                        return SizedBox.shrink();
                      }
                      return TextButton(
                        onPressed: () {
                          final genres = state.genresController.getTags ?? [];
                          final tags = state.tagsController.getTags ?? [];
                          song.genres = genres;
                          song.tags = tags;
                          context.read<SongEditorViewModel>().saveDetails(song);
                        },
                        child: Text("Save"),
                      );
                    }),
              ],
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImage(context, song),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _textField(
                                context,
                                maxLines: 2,
                                value: song.title,
                                placeholder:
                                    localizations.songTitlePlaceholderText,
                                onChange: (value) => song.title = value,
                              ),
                              const SizedBox(height: 16),
                              _textField(
                                context,
                                value: song.artist,
                                placeholder:
                                    localizations.songArtistPlaceholderText,
                                onChange: (value) => song.artist = value,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _textField(context,
                        value: song.language,
                        placeholder: localizations.songLanguagePlaceholderText,
                        onChange: (value) => song.language = value),
                    const SizedBox(height: 16),
                    _checkbox(
                      context,
                      value: song.isOffVocal,
                      onChanged: (value) =>
                          state.updatedWith(isOffVocal: value),
                      label: localizations.isOffVocalText,
                    ),
                    _checkbox(
                      context,
                      value: song.videoHasLyrics,
                      onChanged: (value) =>
                          state.updatedWith(videoHasLyrics: value),
                      label: localizations.hasLyricsText,
                    ),
                    // Genre
                    const SizedBox(height: 16),
                    Text(
                      "Genre",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StringMultilineTags(
                            stringTagController: state.genresController,
                            initialTags: song.genres,
                          ),
                        ),
                        // X button
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => state.genresController.clearTags(),
                        ),
                      ],
                    ),
                    // Tags
                    Text(
                      "Tags",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: StringMultilineTags(
                            stringTagController: state.tagsController,
                            initialTags: song.tags,
                          ),
                        ),
                        // X button
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => state.tagsController.clearTags(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.lyricsLabelText.localizedOf(context),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),

                    _textField(context,
                        maxLines: 10,
                        value: song.lyrics ?? "",
                        placeholder: localizations.lyricsPlaceholderText,
                        onChange: (value) => song.lyrics = value.trim()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, SongDetails song) => Center(
        child: Container(
          width: 100.0,
          height: 100.0,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailURL,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.music_note),
                  fit: BoxFit.cover, // Ensure the image covers the container
                  width: 150.0, // Match the width of the container
                  height: 150.0, // Match the height of the container
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4, // Move the camera button to the lower right
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withOpacity(0.25), // White background with 50% opacity
                    shape: BoxShape.circle, // Circular shape
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt, color: Colors.black),
                    onPressed: () {
                      // Handle camera action
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _textField(
    BuildContext context, {
    required String value,
    required LocalizedString placeholder,
    required Function(String) onChange,
    TextCapitalization textCapitalization = TextCapitalization.words,
    int maxLines = 1,
  }) =>
      TextField(
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
            labelText: placeholder.localizedOf(context),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true),
        controller: TextEditingController(text: value),
        autocorrect: false,
        onChanged: onChange,
      );

  Widget _checkbox(
    BuildContext context, {
    required bool value,
    required Function(bool) onChanged,
    required LocalizedString label,
  }) =>
      Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (value) => onChanged(value ?? false),
          ),
          label.localizedTextOf(context),
        ],
      );
}
