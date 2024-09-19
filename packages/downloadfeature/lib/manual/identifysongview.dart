part of '../downloadfeature.dart';

class IdentifySongView extends StatefulWidget {
  const IdentifySongView({
    super.key,
    required this.flow,
    required this.localizations,
  }) : super();

  final DownloadFlowController flow;
  final DownloadLocalizations localizations;

  @override
  State<IdentifySongView> createState() => _IdentifySongViewState();
}

class SubmissionResult {
  final SubmissionStatus status;

  const SubmissionResult({
    required this.status,
  });

  factory SubmissionResult.idle() =>
      const SubmissionResult(status: SubmissionStatus.idle);
  factory SubmissionResult.loading() =>
      const SubmissionResult(status: SubmissionStatus.loading);
  factory SubmissionResult.success() =>
      const SubmissionResult(status: SubmissionStatus.success);

  factory SubmissionResult.failure({
    required LocalizedString message,
  }) =>
      SubmissionFailure(message: message);
}

enum SubmissionStatus {
  idle,
  loading,
  success,
  failure,
}

class SubmissionFailure extends SubmissionResult {
  final LocalizedString message;

  const SubmissionFailure({
    required this.message,
  }) : super(status: SubmissionStatus.failure);
}

abstract class IdentifySongViewModel extends ChangeNotifier {
  ValueNotifier<SubmissionResult> get submissionResultNotifier;
  String get songUrl;

  void identifySong();
}

class DefaultIdentifySongViewModel extends IdentifySongViewModel {
  DefaultIdentifySongViewModel();

  @override
  final ValueNotifier<SubmissionResult> submissionResultNotifier =
      ValueNotifier(SubmissionResult.idle());

  @override
  @override
  String songUrl = '';

  @override
  void identifySong() async {
    submissionResultNotifier.value = SubmissionResult.loading();

    await Future.delayed(const Duration(seconds: 2));

    // submissionResultNotifier.value = SubmissionResult.success();
    submissionResultNotifier.value = SubmissionResult.failure(
      message: LocalizedString(
        (context) => 'Failed to identify song',
      ),
    );
  }
}

class _IdentifySongViewState extends State<IdentifySongView> {
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
    final submissionResult = viewModel.submissionResultNotifier.value;

    if (submissionResult.status == SubmissionStatus.success) {
      coordinator.navigateToIdentifiedSongDetailsView(context);
    }

    if (submissionResult.status == SubmissionStatus.failure) {
      final message = (submissionResult as SubmissionFailure).message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: message.localizedTextOf(context),
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
          title: const Text('Identify Song'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text(
                'Identify Song',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Enter Song URL',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: viewModel.identifySong,
                child: const Text('Identify'),
              ),
            ],
          ),
        ),
      );
}
