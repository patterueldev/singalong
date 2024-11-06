import 'package:adminfeature/adminfeature.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

part 'master/master_view.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singalong Admin',
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.dark,
      home: const MasterView(),
    );
  }
}
