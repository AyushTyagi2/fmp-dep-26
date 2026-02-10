import 'dart:async';
import 'package:flutter/material.dart';
import 'queue_state.dart';
import 'package:provider/provider.dart';
import '../driver_state.dart';

class DriverQueueScreen extends StatefulWidget {
  const DriverQueueScreen({super.key});

  @override
  State<DriverQueueScreen> createState() => _DriverQueueScreenState();
}

class _DriverQueueScreenState extends State<DriverQueueScreen> {
  QueueState queueState =
      QueueState(status: QueueOfferStatus.none);

  Timer? _timer;

  void _simulateOffer() {
    setState(() {
      queueState = QueueState(
        status: QueueOfferStatus.offered,
        secondsLeft: 15,
      );
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        queueState.secondsLeft--;
      });

      if (queueState.secondsLeft <= 0) {
        timer.cancel();
        setState(() {
          queueState.status = QueueOfferStatus.timedOut;
        });
      }
    });
  }

    void _accept() {
    _timer?.cancel();

    final driverState = context.read<DriverState>();
    driverState.activeTrip = ActiveTrip(
        route: 'Delhi → Jaipur',
        pickupTime: 'Today 6:00 PM',
    );

    setState(() {
        queueState.status = QueueOfferStatus.accepted;
    });

    Navigator.pop(context); // close modal
    }


  void _skip() {
    _timer?.cancel();
    setState(() {
      queueState.status = QueueOfferStatus.skipped;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (queueState.status == QueueOfferStatus.offered) {
        _showOfferModal(context);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Union Queue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: _simulateOffer,
              child: const Text('Simulate Job Offer'),
            ),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                title: const Text('Queue: Delhi → Jaipur (12T)'),
                subtitle: const Text('Your position: #1'),
                trailing: Text(queueState.status.name),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfferModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('🚚 Job Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Route: Delhi → Jaipur'),
              const SizedBox(height: 8),
              Text('Time left: ${queueState.secondsLeft}s'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _skip,
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: _accept,
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }
}
