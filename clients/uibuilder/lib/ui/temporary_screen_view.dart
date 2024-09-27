part of '../main.dart';

class TemporaryScreenView extends StatefulWidget {
  final String name;
  const TemporaryScreenView({
    super.key,
    required this.name,
  });
  @override
  State<TemporaryScreenView> createState() => _TemporaryScreenViewState();
}

class _TemporaryScreenViewState extends State<TemporaryScreenView> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.name,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}
