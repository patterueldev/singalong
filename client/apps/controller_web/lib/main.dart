import 'package:flutter/material.dart';
import 'dart:html' as html;

import 'controller_app.dart';

String getBaseUrl() {
  final location = html.window.location;
  return '${location.protocol}//${location.host}:8080';
}

void main() {
  runApp(const ControllerApp());
}
