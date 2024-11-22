part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatelessWidget {
  // final String encryptionType;
  // final String wifiName;
  // final String wifiPassword;
  final String host;
  final String roomId;

  const ConnectivityPanelWidget({
    super.key,
    // required this.encryptionType,
    // required this.wifiName,
    // required this.wifiPassword,
    required this.host,
    required this.roomId,
  });

  String get encryptionType => "WPA2";
  String get wifiName => "Pat\u2019s XR";
  String get wifiPassword => "aishiteru";

  String get wifiQRData =>
      "WIFI:T:$encryptionType;S:$wifiName;P:$wifiPassword;;";

  String get instructions => """
  Try scanning the QR codes to connect. If that doesn't work, follow these steps:
  1. Connect to Wi-Fi "$wifiName" using password "$wifiPassword".
  2. Open the browser, enter "http://$host and use $roomId".
  """
      .trim();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // instructions
            Expanded(
              child: Text(
                instructions,
                style: TextStyle(
                  fontSize: constraints.maxHeight * 0.015,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

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
          ],
        ),
      );
}
