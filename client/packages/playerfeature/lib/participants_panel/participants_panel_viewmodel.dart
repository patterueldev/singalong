part of '../playerfeature.dart';

abstract class ParticipantsPanelViewModel extends ChangeNotifier {
  ValueNotifier<List<UserParticipant>> participants = ValueNotifier([]);
}

class DefaultParticipantsPanelViewModel extends ParticipantsPanelViewModel {
  final UserParticipantSocketRepository userParticipantRepository;
  DefaultParticipantsPanelViewModel({
    required this.userParticipantRepository,
  }) {
    setup();
  }

  StreamController<List<UserParticipant>>? _participantsController;

  void setup() {
    _participantsController = userParticipantRepository.participantsController;
    _participantsController?.stream.listen((participants) {
      this.participants.value = participants;
    });

    userParticipantRepository.requestParticipantsList();
  }

  @override
  void dispose() {
    _participantsController?.close();
    super.dispose();
  }
}
