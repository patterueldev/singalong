part of '../main.dart';

class NavigatorItem {
  final String name;
  final Widget Function(BuildContext) build;

  const NavigatorItem({required this.name, required this.build});
}
