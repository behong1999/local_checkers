import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:local_chess/components/dead_piece.dart';
import 'package:local_chess/components/piece.dart';
import 'package:local_chess/components/square.dart';
import 'package:local_chess/constant/colors.dart';
import 'package:local_chess/helper/helper_methods.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  // A 2D list as a chess board
  late List<List<ChessPiece?>> board;

  // Selected piece
  ChessPiece? selectedPiece;

  // Default selected square
  int selectedRow = -1;
  int selectedCol = -1;

  // A list of valid moves for the currently selected piece
  // e.g. [[x,y], [x,y], [x,y]]
  List<List<int>> validMoves = [];

  List<ChessPiece> whitePiecesCaptured = [];

  List<ChessPiece> blackPiecesCaptured = [];

  // Boolean to check whose turn it is
  bool isWhiteTurn = true;

  // Initial position of kings (To make it easier to check if king is in check)
  List<int> blackKingPosition = [0, 4];
  List<int> whiteKingPosition = [7, 4];
  bool checkStatus = false;

  // SELECT PIECE
  void pieceSelected(int row, int col) {
    setState(() {
      // No piece has been selected yet and user taps on a piece
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == isWhiteTurn) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
        }
      }

      // If a piece has been selected, user can change to select another piece
      else if (board[row][col] != null &&
          selectedPiece != null &&
          selectedPiece!.isWhite == board[row][col]!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      }

      // If there is a piece selected and user taps on another square that is considered a valid move, move there
      else if (selectedPiece != null &&
          validMoves.any(
            (element) => element[0] == row && element[1] == col,
          )) {
        movePiece(row, col);
      }
      validMoves = calculateRealValidMoves(
        selectedRow,
        selectedCol,
        selectedPiece,
        true,
      );
    });
  }

  // CALCULATE NORMAL VALID MOVES
  List<List<int>> calculateStandardValidMoves(
      int row, int col, ChessPiece? piece) {
    List<List<int>> capableMoves = [];

    if (piece == null) {
      return [];
    }

    // move upward or downward based on piece color for PAWNS
    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        // pawn moves forward if the square is not occupied
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          capableMoves.add([row + direction, col]);
        }

        // pawn can move 1 or 2 square forward if it is at initial position
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null &&
              board[row + direction][col] == null) {
            capableMoves.add([row + 2 * direction, col]);
          }
        }

        // pawn can kill diagonally
        // on the left
        if (isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite != piece.isWhite) {
          capableMoves.add([row + direction, col - 1]);
        }

        // on the right
        if (isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            board[row + direction][col + 1]!.isWhite != piece.isWhite) {
          capableMoves.add([row + direction, col + 1]);
        }
        break;

      case ChessPieceType.rook:
        // horizontal and vertical moves
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1] // right
        ];
        // Create a list of capable moves for every direction
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              // Check if there is a different colored piece in the way. If so, move to that location and capture that piece
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                capableMoves.add([newRow, newCol]);
              }
              break; // Stop "while" loop and move to check the next direction
            }
            capableMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.knight:
        var knightMoves = [
          [-2, -1], // up 2 left 1
          [-2, 1], // up 2 right 1
          [-1, -2], // left 1 up 2
          [-1, 2], // left 1 down 2
          [1, -2], // right 1 up 2
          [1, 2], // right 1 down 2
          [2, -1], // down 2 left 1
          [2, 1], // down 2 right 1
        ];

        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) {
            continue; // Moving to the next move
          }
          // Capture if there is a different colored piece in the way
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              capableMoves.add([newRow, newCol]);
            }
            continue; // Moving to the next move
          }
          capableMoves.add([newRow, newCol]);
        }
        break;

      case ChessPieceType.bishop:
        // Similar to the rook but with diagonal moves
        var directions = [
          [-1, -1], // up left
          [-1, 1], // up right
          [1, -1], // down left
          [1, 1], // down right
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              // Check if there is a different colored piece in the way. If so, move to that location and capture that piece
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                capableMoves.add([newRow, newCol]);
              }
              break;
            }
            capableMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.queen:
        // horizontal, vertical, and diagonal moves
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1], // right
          [-1, -1], // up left
          [-1, 1], // up right
          [1, -1], // down left
          [1, 1], // down right
        ];
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              // Check if there is a different colored piece in the way. If so, move to that location and capture that piece
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                capableMoves.add([newRow, newCol]);
              }
              break;
            }
            capableMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;

      case ChessPieceType.king:
        // horizontal, vertical, and diagonal moves
        var directions = [
          [-1, 0], // up
          [1, 0], // down
          [0, -1], // left
          [0, 1], // right
          [-1, -1], // up left
          [-1, 1], // up right
          [1, -1], // down left
          [1, 1], // down right
        ];
        for (var direction in directions) {
          var newRow = row + direction[0];
          var newCol = col + direction[1];
          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            // Check if there is a different colored piece in the way. If so, move to that location and capture that piece
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              capableMoves.add([newRow, newCol]);
            }
            continue;
          }
          capableMoves.add([newRow, newCol]);
        }
        break;
      default:
    }
    return capableMoves;
  }

  // CALCULATE COMPLICATED VALID MOVES
  List<List<int>> calculateRealValidMoves(
    int row,
    int col,
    ChessPiece? piece,
    bool checkSimulation,
  ) {
    List<List<int>> realValidMoves = [];
    List<List<int>> capableMoves = calculateStandardValidMoves(row, col, piece);

    // After generating all capable moves, filter out any moves that cause the king vulnerable
    if (checkSimulation) {
      for (var move in capableMoves) {
        int endRow = move[0];
        int endCol = move[1];
        if (simulateMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add([endRow, endCol]);
        }
      }
    } else {
      realValidMoves = capableMoves;
    }
    return realValidMoves;
  }

  // SIMULATE/TEST THE FUTURE MOVE TO SEE IF IT'S SAFE (AVOID PUT THE KING IN CHECK)
  bool simulateMoveIsSafe(
      ChessPiece piece, int startRow, int startCol, int endRow, int endCol) {
    // save the current state of the board
    ChessPiece? originalDestinationPiece = board[endRow][endCol];

    // if the piece is the king, save its current position and update to the new one
    List<int>? originalKingPosition;
    if (piece.type == ChessPieceType.king) {
      // get the original position of the king
      originalKingPosition =
          piece.isWhite ? whiteKingPosition : blackKingPosition;

      // update the king position
      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    // start simulating the move
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    // check if our own king will be under attack by the enemy piece when the destination move is simulated
    bool kingInCheck = isKingInCheck(piece.isWhite);

    // restore the board to its original state
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    // if the piece was the king, restore its original position
    if (piece.type == ChessPieceType.king) {
      if (originalKingPosition != null) {
        if (piece.isWhite) {
          whiteKingPosition = originalKingPosition;
        } else {
          blackKingPosition = originalKingPosition;
        }
      }
    }

    // kingInCheck will be true if the king is vulnerable to the enemy piece
    // Hence, only SAFE when the king is not in check
    return !kingInCheck;
  }

  // MOVE PIECE
  void movePiece(int newRow, int newCol) {
    // If the new square has an enemy piece, capture it
    if (board[newRow][newCol] != null) {
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        whitePiecesCaptured.add(capturedPiece);
      } else {
        blackPiecesCaptured.add(capturedPiece);
      }
    }

    // Check if the moving piece is a king
    if (selectedPiece!.type == ChessPieceType.king) {
      // Update the current appropriate king position
      if (selectedPiece!.isWhite) {
        whiteKingPosition = [newRow, newCol];
      } else {
        blackKingPosition = [newRow, newCol];
      }
    }

    board[newRow][newCol] = board[selectedRow][selectedCol];
    board[selectedRow][selectedCol] = null;

    // Check if the king is under attack (isWhiteTurn is true in default so check if black king is checked)
    if (isKingInCheck(!isWhiteTurn)) {
      checkStatus = true;
    } else {
      checkStatus = false;
    }

    // Reset everything after a move
    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
    });

    // Check if the game is over
    if (isCheckMate(!isWhiteTurn)) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title:
                  Text("${isWhiteTurn ? "Black" : "White"} has won the game!"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    resetGame();
                  },
                  child: const Text("New Game"),
                ),
              ]);
        },
      );
    }

    // Change turn
    isWhiteTurn = !isWhiteTurn;
  }

  // IS KING IN CHECK??? (White turn => isWhiteKing == false | Black turn => isWhiteKing == true)
  bool isKingInCheck(bool isWhiteKingAsTarget) {
    List<int> kingPosition =
        isWhiteKingAsTarget ? whiteKingPosition : blackKingPosition;

    // Check if the enemy piece can attack the king
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // Skip empty square and pieces of the same color as the king
        if (board[i][j] == null ||
            board[i][j]!.isWhite == isWhiteKingAsTarget) {
          continue;
        }

        List<List<int>> pieceValidMove =
            calculateRealValidMoves(i, j, board[i][j], false);

        // Check if the king's position is in this piece's valid moves
        if (pieceValidMove.any((element) =>
            element[0] == kingPosition[0] && element[1] == kingPosition[1])) {
          return true;
        }
      }
    }
    return false;
  }

  // CHECKMATE???
  bool isCheckMate(bool isWhiteKing) {
    // If the king is not in check, it is not checkmate
    if (!isKingInCheck(isWhiteKing)) {
      return false;
    }

    // If there is at least one legal move for any piece, it is not checkmate
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        // Skip empty square and pieces of the same color as the king
        if (board[i][j] == null || board[i][j]!.isWhite != isWhiteKing) {
          continue;
        }

        List<List<int>> pieceValidMoves =
            calculateRealValidMoves(i, j, board[i][j], true);

        // If any piece has a legal move, it is not checkmate YET
        if (pieceValidMoves.isNotEmpty) {
          return false;
        }
      }
    }
    // If none of the above are true, CHECKMATE
    return true;
  }

  void resetGame() {
    board = initializeBoard();
    checkStatus = false;
    whitePiecesCaptured.clear();
    blackPiecesCaptured.clear();
    whiteKingPosition = [0, 4];
    blackKingPosition = [7, 4];
    isWhiteTurn = true;
    setState(() {});
  }

  @override
  void initState() {
    board = initializeBoard();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // WHITE PIECES CAPTURED
          Expanded(
            child: RotatedBox(
              quarterTurns: 2,
              child: GridView.builder(
                itemCount: whitePiecesCaptured.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemBuilder: (context, index) => DeadPiece(
                    type: whitePiecesCaptured[index].type, isWhite: true),
              ),
            ),
          ),

          // CHECK STATUS
          Text(
            checkStatus ? "CHECK!" : "",
            style: const TextStyle(color: Colors.red),
          ),

          // GAME BOARD
          Expanded(
            flex: 3,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 8 * 8,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                // Get the row and col position of the current square
                int row = index ~/ 8;
                int col = index % 8;

                // Check if the current square is selected
                bool isSelected = selectedRow == row && selectedCol == col;

                // Check if the current square is a valid move
                bool isValidMove = false;
                for (var position in validMoves) {
                  if (position[0] == row && position[1] == col) {
                    isValidMove = true;
                  }
                }

                return Square(
                  piece: board[row][col],
                  isWhite: isWhite(index),
                  isSelected: isSelected,
                  isValidMove: isValidMove,
                  onTap: () => pieceSelected(row, col),
                );
              },
            ),
          ),

          // BLACK PIECES CAPTURED
          Expanded(
            child: GridView.builder(
              itemCount: blackPiecesCaptured.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) => DeadPiece(
                type: blackPiecesCaptured[index].type,
                isWhite: false,
              ),
            ),
          ),
          ElevatedButton(
              onPressed: () => resetGame(), child: const Text("New Game"))
        ],
      ),
    );
  }
}
