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
                          labelText: 'Room ID',
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
                  decoration: InputDecoration(
                    labelText: 'Room Name',
                    hintText: 'Enter room name',
                  ),
                  onChanged: (value) =>
                      context.read<CreateRoomViewModel>().updateRoomName(value),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Room Passcode',
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
