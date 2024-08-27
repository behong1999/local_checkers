enum ChessPieceType { king, queen, rook, bishop, knight, pawn }

class ChessPiece {
  final ChessPieceType type;
  final bool isWhite;

  ChessPiece({required this.type, required this.isWhite});
}
