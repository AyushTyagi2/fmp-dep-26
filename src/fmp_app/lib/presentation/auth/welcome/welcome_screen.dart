import 'package:flutter/material.dart';
import '../../../routes/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRouter.phone);
          },
          child: const Text('Continue with Phone'),
        ),
      ),
    );
  }
}
