part of 'singalong_api_client.dart';

abstract class SingalongAPIConfiguration {
  String get protocol; //TODO: Might not be needed
  String get host;
  int get apiPort;
  int get socketPort;

  String get apiBaseUrl => "http://$host:$apiPort";
  String get socketBaseUrl => "http://$host:$socketPort";
}
