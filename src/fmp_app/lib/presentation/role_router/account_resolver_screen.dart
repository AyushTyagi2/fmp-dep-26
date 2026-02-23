import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fmp_app/presentation/auth/auth_controller.dart';

class AccountResolverScreen extends StatelessWidget {
  const AccountResolverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.stage == AuthStage.authenticated) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
