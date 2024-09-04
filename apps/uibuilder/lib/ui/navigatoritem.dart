part of '../main.dart';

class NavigatorItem {
  final String name;
  final Widget Function(BuildContext) destination;

  const NavigatorItem({required this.name, required this.destination});
}
