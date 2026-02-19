import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const QrMasterApp());
}

class QrMasterApp extends StatelessWidget {
  const QrMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Master',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
