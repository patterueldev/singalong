part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatelessWidget {
  final String roomId;

  const ConnectivityPanelWidget({
    super.key,
    required this.roomId,
  });

  String get encryptionType => "WPA2";
  String get wifiName => "thursday";
  String get wifiPassword => "aishiteru";

  String get controllerQRData =>
      "http://thursday.local/session/connect?roomId=$roomId";
  String get wifiQRData =>
      "WIFI:T:$encryptionType;S:$wifiName;P:$wifiPassword;;";

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            QrImageView(
              data: wifiQRData,
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
            QrImageView(
              data: controllerQRData,
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
