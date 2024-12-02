part of '../playerfeature.dart';

class ConnectivityPanelWidget extends StatelessWidget {
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

  String get websiteURL => "singalong.fun";
  String get connectivityQRData =>
      "https://singalong.fun/session/connect?roomId=$roomId";

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: 0.69,
        child: LayoutBuilder(
          builder: (context, constraints) => Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              QrImageView(
                data: connectivityQRData,
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
                    fontSize: constraints.maxHeight * 0.02,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                websiteURL,
                style: TextStyle(
                    fontSize: constraints.maxHeight * 0.015,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30)
            ],
          ),
        ),
      );
}
