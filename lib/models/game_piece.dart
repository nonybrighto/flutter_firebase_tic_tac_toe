enum PieceType{win, normal, temp}


class GamePiece{

   final String piece;
   final PieceType pieceType;

    GamePiece({this.piece, this.pieceType});

    GamePiece copyWith({String piece, PieceType pieceType}){

      return GamePiece(
        piece:  piece ?? this.piece,
        pieceType: pieceType ?? this.pieceType
      );
    }  
}