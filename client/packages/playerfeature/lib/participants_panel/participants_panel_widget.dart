part of '../playerfeature.dart';

class ParticipantsPanelWidget extends StatelessWidget {
  final String host;
  final String roomId;
  const ParticipantsPanelWidget({
    super.key,
    required this.host,
    required this.roomId,
  });

  String get controllerQRData => "http://$host/session/connect?roomId=$roomId";

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
        ],
      );
}
