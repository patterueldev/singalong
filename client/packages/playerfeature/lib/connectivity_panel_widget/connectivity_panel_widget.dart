part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatelessWidget {
  final String host;
  final String roomId;

  const ConnectivityPanelWidget({
    super.key,
    required this.host,
    required this.roomId,
  });

  String get encryptionType => "WPA2";
  String get wifiName => "Pat\u2019s XR";
  String get wifiPassword => "aishiteru";

  String get controllerQRData => "http://$host/session/connect?roomId=$roomId";
  String get wifiQRData =>
      "WIFI:T:$encryptionType;S:$wifiName;P:$wifiPassword;;";

  String get instructions => """
  Try scanning the QR codes to connect. If that doesn't work, follow these steps:
  1. Connect to Wi-Fi "$wifiName" using password "$wifiPassword".
  2. Open the browser and type "http://$host".
  """
      .trim();

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
            Text(
              wifiName,
              style: TextStyle(
                  fontSize: constraints.maxHeight * 0.02,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              wifiPassword,
              style: TextStyle(
                  fontSize: constraints.maxHeight * 0.02,
                  fontWeight: FontWeight.bold),
            ),
            // instructions
            Expanded(
              child: Center(
                child: Text(
                  instructions,
                  style: TextStyle(
                    fontSize: constraints.maxHeight * 0.015,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
