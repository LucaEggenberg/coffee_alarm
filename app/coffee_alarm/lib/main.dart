import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // We will create this
import 'pages/settings_page.dart'; // We will create this

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Alarm',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true, // Opt-in to Material 3
      ),
      home: const HomePage(),
      routes: {
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}