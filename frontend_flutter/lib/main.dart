import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'services/secure_storage.dart';

void main() {
  runApp(ItemApp());
}

class ItemApp extends StatefulWidget {
  @override
  State<ItemApp> createState() => _ItemAppState();
}

class _ItemAppState extends State<ItemApp> {
  Widget _defaultScreen = const Center(child: CircularProgressIndicator());

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() async {
    final token = await SecureStorage.getToken();
    setState(() {
      _defaultScreen = token != null ? HomeScreen() : AuthScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _defaultScreen,
      routes: {
        '/home': (context) => HomeScreen(),
        '/auth': (context) => AuthScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        // Removed '/reset' since ResetPasswordScreen needs an email
      },
    );
  }
}
