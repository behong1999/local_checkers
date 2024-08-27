import 'package:flutter/material.dart';
import 'package:local_chess/components/game_board.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GameBoard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
