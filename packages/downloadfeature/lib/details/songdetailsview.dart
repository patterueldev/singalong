part of '../downloadfeature.dart';

class SongDetailsView extends StatefulWidget {
  const SongDetailsView({
    super.key,
    required this.localizations,
  }) : super();

  final DownloadLocalizations localizations;

  @override
  State<StatefulWidget> createState() => _SongDetailsViewState();
}

class _SongDetailsViewState extends State<SongDetailsView> {
  DownloadLocalizations get localizations => widget.localizations;

  @override
  Widget build(BuildContext context) => Consumer<SongDetailsViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            Scaffold(
              appBar: AppBar(
                title: localizations.songDetailsScreenTitleText
                    .localizedTextOf(context),
              ),
              body: _buildBody(context, viewModel),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: viewModel.isLoadingNotifier,
              builder: (context, isLoading, child) => isLoading
                  ? Container(
                      color: Colors.black.withOpacity(0.5),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );

  Widget _buildBody(BuildContext context, SongDetailsViewModel viewModel) =>
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: Container(
                width: 150.0,
                height: 150.0,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: "",
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.music_note),
                        fit: BoxFit
                            .cover, // Ensure the image covers the container
                        width: 150.0, // Match the width of the container
                        height: 150.0, // Match the height of the container
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4, // Move the camera button to the lower right
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(
                              0.25), // White background with 50% opacity
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
            ),
            const SizedBox(height: 16),
            _textField(
                value: viewModel.songTitle,
                placeholder: localizations.songTitlePlaceholderText,
                onChange: viewModel.updateSongTitle),
            const SizedBox(height: 16),
            _textField(
                value: viewModel.songArtist,
                placeholder: localizations.songArtistPlaceholderText,
                onChange: viewModel.updateSongArtist),
            const SizedBox(height: 16),
            _textField(
                value: viewModel.songLanguage,
                placeholder: localizations.songLanguagePlaceholderText,
                onChange: viewModel.updateSongLanguage),
            const SizedBox(height: 16),
            _checkbox(
              value: viewModel.isOffVocal,
              onChanged: viewModel.toggleOffVocal,
              label: localizations.isOffVocalText,
            ),
            _checkbox(
              value: viewModel.videoHasLyrics,
              onChanged: viewModel.toggleVideoHasLyrics,
              label: localizations.hasLyricsText,
            ),
            const SizedBox(height: 16),
            _textField(
                maxLines: 5,
                value: viewModel.songLyrics,
                placeholder: localizations.lyricsPlaceholderText,
                onChange: viewModel.updateSongLyrics),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => viewModel.download(false),
              child: localizations.downloadOnlyText.localizedTextOf(context),
            ),
            ElevatedButton(
              onPressed: () => viewModel.download(true),
              child:
                  localizations.downloadAndReserveText.localizedTextOf(context),
            ),
          ],
        ),
      );

  Widget _textField({
    required String value,
    required LocalizedString placeholder,
    required Function(String) onChange,
    int maxLines = 1,
  }) =>
      TextField(
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: placeholder.localizedOf(context),
            border: const OutlineInputBorder(),
            alignLabelWithHint: true),
        controller: TextEditingController(text: value),
        autocorrect: false,
        onChanged: onChange,
      );

  Widget _checkbox({
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
