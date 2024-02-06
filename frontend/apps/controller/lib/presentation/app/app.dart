part of '../../main.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider<ReservationsViewModel>(
        // create: (context) => DefaultReservationsViewModel(),
        create: (context) => PreviewReservationsViewModel(),
        child: const ReservationsScreen(),
      ),
    );
  }
}
