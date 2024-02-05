part of '../../reservations_feature.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Reservations')),
        body: Consumer<ReservationsViewModel>(
          builder: (context, viewModel, child) => viewModel.songs.isEmpty
              ? emptyScreen()
              : ListView.builder(
                  itemCount: viewModel.songs.length,
                  itemBuilder: (context, index) {
                    final song = viewModel.songs[index];
                    return ListTile(
                      leading: CachedNetworkImage(
                        imageUrl: song.imageUrl ?? '',
                        placeholder: (context, url) =>
                            const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                            Assets.images.noImagePlaceholder.image(),
                      ),
                      title: Text(song.title),
                      subtitle: Text(song.artist),
                      trailing: Text(song.album),
                    );
                  },
                ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<ReservationsViewModel>().songBook(),
          shape: const CircleBorder(),
          child: const Icon(Icons.book),
        ),
      );

  Widget emptyScreen() => const Center(
        child: Text('No Reservations Found'),
      );
}
