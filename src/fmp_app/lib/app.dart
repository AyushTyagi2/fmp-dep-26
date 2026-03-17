import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/auth/auth_controller.dart';
import 'presentation/driver/driver_state.dart';
import 'presentation/fleetmgr/fleet_state.dart';
import 'routes/app_router.dart';
import 'package:fmp_app/presentation/auth/auth_api.dart';
import 'core/theme/app_theme.dart';
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthApi>(
          create: (_) => AuthApi(),
        ),
         ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthApi>()),
        ),
        ChangeNotifierProvider<FleetState>(
          create: (_) => FleetState(),
        ),
        
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRouter.welcome,
        routes: AppRouter.routes,
      ),
    );
  }
}
