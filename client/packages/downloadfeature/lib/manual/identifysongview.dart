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
      viewModel.submissionStateNotifier.addListener(_submissionResultListener);
    });
  }

  @override
  void dispose() {
    final viewModel = context.read<IdentifySongViewModel>();
    viewModel.submissionStateNotifier.removeListener(_submissionResultListener);
    super.dispose();
  }

  void _submissionResultListener() {
    final viewModel = context.read<IdentifySongViewModel>();
    final result = viewModel.submissionStateNotifier.value;

    if (result is IdentifySubmissionSuccess) {
      coordinator.navigateToIdentifiedSongDetailsView(
        context,
        details: result.identifiedSongDetails,
      );
    }

    if (result is IdentifySubmissionFailure) {
      final exception = result.exception;
      if (exception is DownloadException) {
        debugPrint("exception type: ${exception.type}");
        if (exception.type == ExceptionType.alreadyExists) {
          _showErrorDialog(context, exception, localizations);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            exception.localizedFrom(localizations).localizedTextOf(context),
      ));
    }
  }

  void _showErrorDialog(BuildContext context, DownloadException exception,
      DownloadLocalizations localizations) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content:
              Text(exception.localizedFrom(localizations).localizedOf(context)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Handle Reserve action
                Navigator.of(context).pop();
              },
              child: Text('Reserve'),
            ),
            TextButton(
              onPressed: () {
                // Handle View action
                Navigator.of(context).pop();
              },
              child: Text('View'),
            ),
            TextButton(
              onPressed: () {
                // Handle Cancel action
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Consumer<IdentifySongViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            _buildBody(viewModel),
            ValueListenableBuilder<IdentifySubmissionState>(
              valueListenable: viewModel.submissionStateNotifier,
              builder: (context, submissionResult, child) {
                if (submissionResult.status ==
                    IdentifySubmissionStatus.loading) {
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
                autocorrect: false,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: localizations.identifySongUrlPlaceholderText
                      .localizedOf(context),
                  alignLabelWithHint: true,
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
