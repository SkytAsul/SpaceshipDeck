import 'package:deck_controller/communication_bus.dart';
import 'package:flutter/material.dart';

void main() async {
  await connect("::1", 58451);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spaceship Deck Controller',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF500073)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF500073),
          brightness: Brightness.dark,
        ),
      ),
      home: Material(child: Center(child: Text("Hello"))),
    );
  }
}
