import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const MathApps());
}

class MathApps extends StatelessWidget {
  const MathApps({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Apps',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const HomeScreen(),
    );
  }
}