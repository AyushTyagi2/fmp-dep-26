import 'package:flutter/material.dart';
import 'app_session.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.restore();
  runApp(const MyApp());
}