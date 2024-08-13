import 'package:flutter/material.dart';
import 'package:password/ui/screens/homepage.dart';
import 'package:password/ui/screens/password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final bool isPasswordEnabled = prefs.getBool("isEnabled") ?? false;
  runApp(MainApp(
    isEnabled: isPasswordEnabled,
  ));
}

class MainApp extends StatelessWidget {
  bool isEnabled;
  MainApp({
    super.key,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isEnabled ? const PasswordScreen() : const Homepage(),
    );
  }
}
