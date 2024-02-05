part of '../../reservations_feature.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
      ),
      body: const Center(
        child: Text('Reservations Screen'),
      ),
    );
  }
}
