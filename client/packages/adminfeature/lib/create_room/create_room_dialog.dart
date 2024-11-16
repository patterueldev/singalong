part of '../adminfeature.dart';

class CreateRoomDialog extends StatelessWidget {
  const CreateRoomDialog({super.key});

  @override
  Widget build(BuildContext context) => Consumer<CreateRoomViewModel>(
        builder: (context, viewModel, child) => Stack(
          children: [
            _buildDialog(context),
            ValueListenableBuilder(
              valueListenable: viewModel.isLoadingNotifier,
              builder: (context, isLoading, child) => Positioned.fill(
                child: isLoading
                    ? Container(
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            ValueListenableBuilder(
                valueListenable: viewModel.promptNotifier,
                builder: (context, prompt, child) {
                  if (prompt != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(prompt.title.localizedOf(context)),
                          content: Text(prompt.message.localizedOf(context)),
                          actions: prompt.actions
                              .map(
                                (action) => TextButton(
                                  onPressed: () {
                                    action.action?.call();
                                    Navigator.of(context).pop();
                                  },
                                  child:
                                      Text(action.title.localizedOf(context)),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    });
                  }
                  return const SizedBox.shrink();
                }),
            ValueListenableBuilder(
              valueListenable: viewModel.roomCreatedNotifier,
              builder: (context, roomCreated, child) {
                if (roomCreated) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    // TODO: We can also pass the created and let the user automatically connect to the room
                    Navigator.of(context).pop(roomCreated);
                  });
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      );

  Widget _buildDialog(BuildContext context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Room'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Room ID *',
                          hintText: 'Enter room ID',
                        ),
                        controller: TextEditingController(
                          text: context.watch<CreateRoomViewModel>().roomId,
                        ),
                        readOnly: true,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () =>
                          context.read<CreateRoomViewModel>().generateRoomID(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Room Name *',
                    hintText: 'Enter room name',
                  ),
                  onChanged: (value) =>
                      context.read<CreateRoomViewModel>().updateRoomName(value),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Room Passcode (Optional)',
                    hintText: 'Enter room passcode',
                  ),
                  onChanged: (value) => context
                      .read<CreateRoomViewModel>()
                      .updateRoomPasscode(value),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<CreateRoomViewModel>().create(),
                      child: Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
