import 'package:connectfeature/connectfeature.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sessionfeature/sessionfeature.dart';

part 'ui/navigatoritem.dart';
part 'ui/previewerviewmodel.dart';
part 'ui/previewerview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Singalong UI Builder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider<PreviewerViewModel>(
        create: (ctx) => DefaultPreviewerViewModel(),
        child: const PreviewerView(),
      ),
    );
  }
}