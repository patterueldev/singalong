part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatelessWidget {
  final String roomId;

  const ConnectivityPanelWidget({
    super.key,
    required this.roomId,
  });

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
