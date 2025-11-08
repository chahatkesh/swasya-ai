import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PHCNurseApp());
}

class PHCNurseApp extends StatelessWidget {
  const PHCNurseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PHC AI Co-Pilot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
