part of '../playerfeature.dart';

class ReservedWidget extends StatefulWidget {
  const ReservedWidget({super.key});

  @override
  State<ReservedWidget> createState() => _ReservedWidgetState();
}

// this is just a horizontal widget on top of the screen
class _ReservedWidgetState extends State<ReservedWidget> {
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  // Adjustable variables
  final Duration scrollInterval =
      const Duration(milliseconds: 50); // Reduced interval
  double get scrollAmount => 20.0;
  final Duration animationDuration =
      const Duration(milliseconds: 500); // Reduced duration

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
  Widget build(BuildContext context) => Consumer<ReservedViewModel>(
        builder: (context, viewModel, child) => _buildList(viewModel),
      );

  Widget _buildList(ReservedViewModel viewModel) => ValueListenableBuilder(
        valueListenable: viewModel.reservedViewStateNotifier,
        builder: (context, List<ReservedSongItem> songs, child) =>
            LayoutBuilder(
          builder: (context, constraints) => ListView.builder(
            scrollDirection: Axis.horizontal,
            controller: _scrollController,
            itemCount: songs.length,
            itemBuilder: (context, index) =>
                buildItem(songs[index], constraints.maxHeight * 0.8),
          ),
        ),
      );

  Widget buildItem(ReservedSongItem song, double height) => Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(height / 2),
              child: Stack(
                children: [
                  Container(
                    color: Colors.grey,
                    height: height,
                    width: height,
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailURL.toString(),
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.music_note),
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (song.currentPlaying)
                    Container(
                      padding: const EdgeInsets.all(4),
                      height: height,
                      width: height,
                      color: Colors.grey.withAlpha(100),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                strokedText(
                  song.title,
                  style: TextStyle(
                    fontSize: height * 0.4,
                    decoration: song.currentPlaying
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                  softWrap: false,
                ),
                const SizedBox(width: 16),
                strokedText(
                  '${song.artist} | ${song.reservingUser}',
                  style: TextStyle(fontSize: height * 0.3),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
      );

  Widget strokedText(
    String text, {
    TextStyle style = const TextStyle(),
    bool? softWrap,
  }) =>
      Stack(
        children: [
          Text(
            text,
            style: style.copyWith(
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = Colors.black45,
            ),
            softWrap: softWrap,
          ),
          Text(
            text,
            style: style.copyWith(color: Colors.white),
            softWrap: softWrap,
          ),
        ],
      );

  @override
  void dispose() {
    _scrollTimer?.cancel();
    super.dispose();
  }
}
