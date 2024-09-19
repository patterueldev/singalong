part of '../downloadfeature.dart';

class IdentifySongView extends StatefulWidget {
  const IdentifySongView({
    super.key,
    required this.assets,
    required this.flow,
    required this.localizations,
  }) : super();

  final DownloadAssets assets;
  final DownloadFlowController flow;
  final DownloadLocalizations localizations;

  @override
  State<IdentifySongView> createState() => _IdentifySongViewState();
}

class _IdentifySongViewState extends State<IdentifySongView> {
  DownloadAssets get assets => widget.assets;
  DownloadFlowController get coordinator => widget.flow;
  DownloadLocalizations get localizations => widget.localizations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<IdentifySongViewModel>();
      viewModel.submissionResultNotifier.addListener(_submissionResultListener);
    });
  }

  @override
  void dispose() {
    final viewModel = context.read<IdentifySongViewModel>();
    viewModel.submissionResultNotifier
        .removeListener(_submissionResultListener);
    super.dispose();
  }

  void _submissionResultListener() {
    final viewModel = context.read<IdentifySongViewModel>();
    final result = viewModel.submissionResultNotifier.value;

    if (result is SubmissionSuccess) {
      coordinator.navigateToIdentifiedSongDetailsView(
        context,
        details: result.identifiedSongDetails,
      );
    }

    if (result is SubmissionFailure) {
      final exception = result.exception;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            exception.localizedFrom(localizations).localizedTextOf(context),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<IdentifySongViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            _buildBody(viewModel),
            ValueListenableBuilder<SubmissionResult>(
              valueListenable: viewModel.submissionResultNotifier,
              builder: (context, submissionResult, child) {
                if (submissionResult.status == SubmissionStatus.loading) {
                  return Positioned.fill(
                    child: Container(
                      color: Colors.black54,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      );

  Widget _buildBody(IdentifySongViewModel viewModel) => Scaffold(
        appBar: AppBar(
          title: localizations.identifySongScreenTitleText
              .localizedTextOf(context),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              assets.identifySongBannerImage.image(height: 200),
              const SizedBox(height: 16),
              TextField(
                maxLines: 5,
                onChanged: viewModel.updateSongUrl,
                controller: TextEditingController(text: viewModel.songUrl),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localizations.identifySongUrlPlaceholderText
                      .localizedOf(context),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: viewModel.identifySong,
                child: localizations.identifySongSubmitButtonText
                    .localizedTextOf(context),
              ),
            ],
          ),
        ),
      );
}
