class Colour

  BLACK : new Colour("BLACK")
  WHITE : new Colour("WHITE")

  constructor: (@name) ->

  flip: ->
    if @ == Colour::BLACK then Colour::WHITE else Colour::BLACK

class Piece
  constructor: (@colour, @board) ->
    deltaI = @colour == Colour::BLACK ? -1 : 1
    @vectors = [[deltaI, -1], [deltaI, 1]]
    @board.pieces[colour].push(@)
    @value = 1

  isKinged: ->
    @square? and (colour is Colour::WHITE and @square.row is 7 or @square.row == 0)

  move: (square) ->
    @board.movePiece(@,square)

  take: (piece, jumpTo) ->
    @board.removePiece(piece)
    @move(jumpTo)

class King extends Piece
  constructor: (@colour, @board) ->
    super @colour, @board
    @vectors = [[1, -1], [1, 1],[[-1, -1], [-1, 1]]]
    @value = 2

  isKinged: ->
    false

class Square
  constructor: (@row,@col,@colour) ->

  isEmpty: -> not @piece?

class DraughtsBoard
  constructor: ->
    @pieces = {}
    @pieces[Colour::WHITE] = []
    @pieces[Colour::BLACK] = []

    @squares = []
    for i in [0..7]
      @squares.push(row = [])
      for j in [0..7]
        row = new Square(i,j, if i % 2 == j % 2 then Colour::BLACK else Colour:WHITE)

  initGame: ->
    @pieces[Colour::WHITE] = []
    @pieces[Colour::BLACK] = []
    for row, i in @squares
      for square, j in row
        if square.colour == Colour::BLACK and !(i == 3 or i == 4)
          new Piece((if i < 3 then Colour::BLACK else Colour::WHITE), @).move(square)
        else
          square.piece = null
    @

  toString: ->
    rowSeparator = "--------" + "---------";
    ret = "#{rowSeparator}\n"
    for row in @squares
      for square in row
        name = piece?.colour.name.substr(0, 1)
        ret = "#{ret}|#{ if piece? then name.toLowerCase() else (if square.color == Colour::BLACK then '*' else ' ')}"
      ret = "#{ret}|\n#{rowSeparator}\n"
    ret

  getSquare: (i,j) ->
    if @squares[i]? then @squares[i][j]

  removePiece: (piece) ->
    piece.square.piece = null if piece.square?
    piece.square = null
    index = @pieces[piece.colour].indexOf(piece)
    @pieces[piece.colour].remove(index) if index is not -1

  movePiece: (piece, square) ->
    throw "cannot move to #{square} as it contains #{square.piece}" if not square.isEmpty()
    piece.square.piece = null if piece.square? # remove piece from old square
    @square = square
    @square.piece = @


class ComputerPlayer
  depth: 2

  constructor: (@board, @colour) ->
    @takenPieces = {}

  move: ->
    try
      @pickMove(@board.pieces[@colour], @board.pieces[@colour.flip], @colour, 0, false, 0)
    finally
      @takePieces = {}

  pickMove: (pieces, opponentPieces, colour, depth, hopping, score) ->

    bestMove = null
    for piece in pieces

      continue if @takePieces[piece]?
      fromSquare = piece.square

      for vector in piece.vectors

        current = null
        toSquare = @board.getSquare(fromSquare.i + vector[0], fromSquare.j + vector[1])

        continue if not @canMove(toSquare, colour)

        if not toSquare.isEmpty()

          jumpTo = board.getSquare(toSquare.i + vector[0], toSquare.j + vector[1])
          continue if not jumpTo? or not jumpTo.isEmpty()

          takenPiece = toSquare.piece
          @takenPieces[takenPiece] = true

          piece.take(takenPiece, jumpTo)

          if piece.isKinged()
            current = new Move(piece, fromSquare, toSquare, jumpTo, score + takenPiece.value)
            if depth < @depth
              counterMove = @pickMove(@board.pieces[colour.flip()], board.pieces[colour],
                colour.flip(), depth + 1, false, 0)
              current.score -= counterMove.score if counterMove?
          else
            current = @pickMove([piece], opponentPieces, colour, depth, true, score + takenPiece.value)
            (current = new Move(piece, fromSquare, jumpTo, score + takenPiece.value)) unless current?

          if current.hops.length is 0
            current.to = jumpTo

          current.from = fromSquare
          current.hops.push(toSquare)

          takePieces[takenPiece] = null
          piece.move(fromSquare)
          takenPiece.move(toSquare)

        else

          current = new Move(piece, fromSquare,
              if hopping then fromSquare else toSquare,
              if piece.isKinged() then score + 2 else score)

          if depth < @depth

            piece.move(toSquare)

            counterMove = @pickMove(@board.pieces[colour.flip()], @board.pieces[colour], depth + 1, false, 0)
            current.score -= counterMove.score if counterMove?

            piece.move(fromSquare)

    if not bestMove? or current.takesPieces() and not bestMove.takesPieces() or current.score > bestMove.score and (not bestMove.takesPieces() or current.isTakesPieces())
      bestMove = current

  canMove: (square, colour) ->
    not(not square? or not square.isEmpty() and square.piece.colour == colour)



class Move
  constructor: (@piece, @from, @to, @score) ->
    @hops = []

  take: ->
    # TODO

