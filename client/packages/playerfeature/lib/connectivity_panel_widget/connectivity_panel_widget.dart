part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatefulWidget {
  @override
  State<ConnectivityPanelWidget> createState() =>
      _ConnectivityPanelWidgetState();
}

class _ConnectivityPanelWidgetState extends State<ConnectivityPanelWidget> {
  final roomId = '123456';
  final qrData = 'https://youtu.be/dQw4w9WgXcQ'; // Rick Roll

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Room ID: $roomId',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 20),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200.0,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.white,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.white,
            ),
          ),
        ],
      );
}
