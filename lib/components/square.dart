import 'package:flutter/material.dart';
import 'package:local_chess/components/piece.dart';
import 'package:local_chess/constant/colors.dart';

class Square extends StatelessWidget {
  final bool isWhite;
  final ChessPiece? piece;
  final bool isSelected;
  final bool isValidMove;
  final void Function()? onTap;
  const Square({
    super.key,
    this.piece,
    required this.isWhite,
    required this.isSelected,
    required this.isValidMove,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? squareColor;

    if (isSelected) {
      squareColor = Colors.green;
    } else if (isValidMove) {
      squareColor = Colors.green[200];
    } else {
      squareColor = isWhite ? backgroundColor : foregroundColor;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.grey[800]!,
          ),
          color: squareColor,
        ),
        child: piece != null
            ? Image.asset(
                "images/${piece!.type.name}_${piece!.isWhite ? 'white' : 'black'}.png",
              )
            : null,
      ),
    );
  }
}
