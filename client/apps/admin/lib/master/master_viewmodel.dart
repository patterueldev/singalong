part of '../_main.dart';

abstract class MasterViewModel extends ChangeNotifier {
  Room get room;
}

class DefaultMasterViewModel extends MasterViewModel {
  @override
  final Room room;
  DefaultMasterViewModel({
    required this.room,
  });
}
