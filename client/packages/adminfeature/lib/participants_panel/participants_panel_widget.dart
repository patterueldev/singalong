part of '../adminfeature.dart';

class ParticipantsPanelWidget extends StatelessWidget {
  const ParticipantsPanelWidget({super.key});

  @override
  Widget build(BuildContext context) => Consumer<ParticipantsPanelViewModel>(
        builder: (context, viewModel, child) => ValueListenableBuilder(
          valueListenable: viewModel.participants,
          builder: (context, participants, child) {
            return _buildList(participants);
          },
        ),
      );

  Widget _buildList(List<UserParticipant> participants) => ListView.builder(
        itemCount: participants.length,
        itemBuilder: (context, index) {
          final user = participants[index];
          return ListTile(
            title: Text(user.name),
            subtitle: Text('Songs played: ${user.songsFinished}'),
          );
        },
      );
}
