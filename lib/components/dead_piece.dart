import 'package:flutter/material.dart';
import 'package:local_chess/components/piece.dart';

class DeadPiece extends StatelessWidget {
  final ChessPieceType type;
  final bool isWhite;
  const DeadPiece({super.key, required this.type, required this.isWhite});

  @override
  Widget build(BuildContext context) {
    final String path =
        "images/${type.name}_${isWhite ? 'white' : 'black'}.png";
    return Image.asset(
      path,
      color: isWhite ? Colors.grey[200] : Colors.grey[900],
    );
  }
}
