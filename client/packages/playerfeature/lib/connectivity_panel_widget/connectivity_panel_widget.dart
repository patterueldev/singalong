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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: constraints.maxHeight * 0.15,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.white,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.white,
              ),
            ),
            Text(
              roomId,
              style: TextStyle(fontSize: constraints.maxHeight * 0.03),
            ),
          ],
        ),
      );
}
