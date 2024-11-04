part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatefulWidget {
  @override
  State<ConnectivityPanelWidget> createState() =>
      _ConnectivityPanelWidgetState();
}

// TODO: Not a priority now, but the room ID should be dynamic
class _ConnectivityPanelWidgetState extends State<ConnectivityPanelWidget> {
  String get roomId => '569841';
  String get qrData => "http://thursday.local/session/connect?roomId=$roomId";

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: constraints.maxHeight * 0.15,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.white,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.white,
              ),
            ),
            Text(
              roomId,
              style: TextStyle(
                  fontSize: constraints.maxHeight * 0.03,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
}
