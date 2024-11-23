part of '../playerfeature.dart';

class ParticipantsPanelWidget extends StatefulWidget {
  final String host;
  final String roomId;

  const ParticipantsPanelWidget({
    super.key,
    required this.host,
    required this.roomId,
  });

  @override
  State<ParticipantsPanelWidget> createState() =>
      _ParticipantsPanelWidgetState();
}

class _ParticipantsPanelWidgetState extends State<ParticipantsPanelWidget> {
  String get host => widget.host;
  String get roomId => widget.roomId;

  String get controllerQRData => "http://$host/session/connect?roomId=$roomId";

  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  // Adjustable variables
  final Duration scrollInterval =
      const Duration(milliseconds: 50); // Reduced interval
  double get scrollAmount => 5.0;
  final Duration animationDuration =
      const Duration(milliseconds: 500); // Reduced duration

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      debugPrint("Starting auto-scrolling");
      _scrollTimer = Timer.periodic(scrollInterval, (timer) {
        if (_scrollController.hasClients) {
          final maxScrollExtent = _scrollController.position.maxScrollExtent;
          final currentScrollPosition = _scrollController.position.pixels;
          final newScrollPosition = currentScrollPosition + scrollAmount;

          if (newScrollPosition >= maxScrollExtent) {
            Future.delayed(const Duration(seconds: 2), () {
              _scrollController.jumpTo(0.0);
            });
          } else {
            _scrollController.animateTo(
              newScrollPosition,
              duration: animationDuration,
              curve: Curves.linear,
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<ParticipantsPanelViewModel>(
        builder: (context, viewModel, child) => ValueListenableBuilder(
          valueListenable: viewModel.participants,
          builder: (context, participants, child) => LayoutBuilder(
            builder: (context, constraints) => Column(
              children: [
                Expanded(child: _buildList(participants)),
                _buildQR(constraints),
              ],
            ),
          ),
        ),
      );

  Widget _buildList(List<UserParticipant> participants) => ListView.builder(
        controller: _scrollController,
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final user = participants[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text(
                'Done: ${user.songsFinished}\nNext: ${user.songsUpcoming}'),
          );
        },
      );

  Widget _buildQR(BoxConstraints constraints) => Column(
        children: [
          QrImageView(
            data: controllerQRData,
            version: QrVersions.auto,
            size: constraints.maxHeight * 0.15,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.white,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.white,
            ),
          ),
          Text(
            roomId,
            style: TextStyle(
              fontSize: constraints.maxHeight * 0.03,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30)
        ],
      );
}
