part of '../main.dart';

class MasterView extends StatefulWidget {
  const MasterView({super.key});

  @override
  _MasterViewState createState() => _MasterViewState();
}

class _MasterViewState extends State<MasterView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Handle menu button press
          },
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(),
        ),
      ),
      body: Row(
        children: [
          // Left half
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Top left quarter
                Expanded(
                  flex: 1,
                  child: _buildTopLeft(),
                ),
                const Divider(),
                // Bottom left quarter
                Expanded(
                  flex: 2,
                  child: _buildBottomLeft(),
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          // Right half
          Expanded(
            flex: 1,
            child: _buildRightHalf(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopLeft() => Container(
        child: Center(child: Text('Top Left Corner')),
      );

  Widget _buildBottomLeft() => Container(
        child: Center(child: Text('Bottom Left Corner')),
      );

  Widget _buildRightHalf() => Container(
        child: Center(child: Text('Right Half Edge')),
      );
}