class KeyType
  id : 0
  constructor: ->
    @id = ++KeyType::id
  toString: -> @id

class Colour
  BLACK : new Colour("BLACK")
  WHITE : new Colour("WHITE")

  constructor: (@name) ->

  flip: ->
    if @ is Colour::BLACK then Colour::WHITE else Colour::BLACK

  toString: -> @name

black = Colour::BLACK
white = Colour::WHITE

class Piece extends KeyType
  constructor: (@colour, @board) ->
    super()
    deltaI = if @colour is black then -1 else 1
    @vectors = [[deltaI, -1], [deltaI, 1]]
    @board.addPiece(@)
    @value = 1

  isKinged: ->
    @square? and (@colour is white and @square.row is 7 or @square.row is 0)

  move: (square) ->
    @board.movePiece(@,square)

  take: (piece, jumpTo) ->
    @board.removePiece(piece)
    @move(jumpTo)

  getMove: (square) ->
    return null unless square? and square.isEmpty()
    colDelta = square.col - @square.col
    rowDelta = square.row - @square.row
    if Math.abs(colDelta) == 2 and Math.abs(rowDelta) == 2
      hopped = @board.getSquare(@square.row + rowDelta / 2, @square.col + colDelta / 2)
      if hopped? and not hopped.isEmpty() and hopped.piece.colour is @colour.flip()
        if @ instanceof King or rowDelta / 2 == @vectors[0][0]
          ret = new Move(@, @square, square, 1)
          ret.hops.push(hopped)
          return ret
    else if Math.abs(colDelta) == 1 and Math.abs(rowDelta) == 1
      if @ instanceof King or rowDelta == @vectors[0][0]
        return new Move(@, @square, square, 0)
    return null

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

  toString: ->
    "#{'abcdefgh'[@col]},#{@row}"

class DraughtsBoard
  constructor: (factory)->
    @pieces = {}
    @pieces[white] = []
    @pieces[black] = []
    @publish = true

    @squares = []
    for i in [0..7]
      row = []
      @squares.push(row)
      for j in [0..7]
        row.push new Square(i,j, if i % 2 == j % 2 then black else white)

    if factory?
      board = @
      cols = {}
      cols[name] = i for name,i in 'abcdefgh'.split('')

      factory.call({
          black: (args...) ->
            new Piece(black, board).move(board.getSquare(args[i + 1], args[i])) for col, i in args by 2
        white: (args...) ->
            new Piece(white, board).move(board.getSquare(args[i + 1], args[i])) for col, i in args by 2
        }, cols
      )

  initGame: ->
    @pieces[white] = []
    @pieces[black] = []
    for row, i in @squares
      for square, j in row
        if square.colour == black and !(i == 3 or i == 4)
          new Piece((if i < 3 then white else black), @).move(square)
        else
          square.piece = null
    @

  toString: ->
    rowSeparator = "--------" + "---------";
    ret = "#{rowSeparator}\n"
    for row in [].concat(@squares).reverse()
      for square in row
        piece = square.piece
        name = piece?.colour.name.substr(0, 1)
        name = name.toLowerCase() if piece?.value is 1
        ret = "#{ret}|#{ if piece? then name else (if square.color == black then '*' else ' ')}"
      ret = "#{ret}|\n#{rowSeparator}\n"
    ret

  getSquare: (i,j) ->
    if @squares[i]? then @squares[i][j]

  addPiece: (piece) ->
    @pieces[piece.colour].push(piece)
    if @publish and @listener
      @listener.addPiece(piece)

  removePiece: (piece) ->
    piece.square.piece = null if piece.square?
    piece.square = null
    index = @pieces[piece.colour].indexOf(piece)
    @pieces[piece.colour].remove(index) if index is not -1

    if @publish and @listener?
      @listener.remove(piece)

  movePiece: (piece, square) ->
    throw "cannot move to #{square} as it contains #{square.piece}" if not square.isEmpty()
    piece.square.piece = null if piece.square? # remove piece from old square
    piece.square = square
    square.piece = piece

    if @publish and @listener?
      @listener.move(piece, square)



class ComputerPlayer
  depth: 4

  constructor: (@board, @colour) ->
    @takenPieces = {}

  move: ->
    try
      @board.publish = false
      ret = @pickMove(@board.pieces[@colour], @board.pieces[@colour.flip], @colour, 0, false, 0)
    finally
      @board.publish = true
      @takenPieces = {}

  pickMove: (pieces, opponentPieces, colour, depth, hopping, score) ->

    bestMove = null
    for piece in pieces when piece?.square?

      continue if @takenPieces[piece]?
      fromSquare = piece.square

      for vector in piece.vectors

        current = null

        toSquare = @board.getSquare(fromSquare.row + vector[0], fromSquare.col + vector[1])

        continue if not @canMove(toSquare, colour)

        if not toSquare.isEmpty()

          jumpTo = @board.getSquare(toSquare.row + vector[0], toSquare.col + vector[1])
          continue if not jumpTo? or not jumpTo.isEmpty()

          takenPiece = toSquare.piece
          @takenPieces[takenPiece] = true
          toSquare.piece = null
          takenPiece.square = null
          piece.move(jumpTo)

          if piece.isKinged()
            current = new Move(piece, fromSquare, jumpTo, score + takenPiece.value)
            if depth < @depth
              counterMove = @pickMove(@board.pieces[colour.flip()], @board.pieces[colour],
                colour.flip(), depth + 1, false, 0)
              current.score -= counterMove.score if counterMove?
          else
            current = @pickMove([piece], opponentPieces, colour, depth, true, score + takenPiece.value)
            (current = new Move(piece, fromSquare, jumpTo, score + takenPiece.value)) unless current?

          if current.hops.length is 0
            current.to = jumpTo

          current.from = fromSquare
          current.hops.push(toSquare)

          @takenPieces[takenPiece] = null
          piece.move(fromSquare)
          takenPiece.move(toSquare)

        else

          current = new Move(piece, fromSquare,
              if hopping then fromSquare else toSquare,
              if piece.isKinged() then score + 2 else score)

          if depth < @depth

            piece.move(toSquare)

            counterMove = @pickMove(@board.pieces[colour.flip()], @board.pieces[colour], colour.flip(), depth + 1, false, 0)
            current.score -= counterMove.score if counterMove?

            piece.move(fromSquare)

#        console.log("#{colour} scored move: #{current}: \"#{current.score}\"") if depth is 0

        bestMove = current if current?.betterThan(bestMove)

    bestMove


  canMove: (square, colour) ->
    not(not square? or not square.isEmpty() and square.piece.colour == colour)

class Move
  constructor: (@piece, @from, @to, @score) ->
    @hops = []
    @board = @piece.board

  take: ->
    unless @hops.length is 0
      opponentPieces = @board.pieces[@piece.colour.flip()]
      for hop in @hops
        @board.removePiece(hop.piece)

    @piece.move(@to)

    if @piece.isKinged()
      @board.removePiece(@piece)
      @piece = new King(@piece.colour, @board).move(@to)


  betterThan: (move)->
    testPieceTaking = move? and (not move.takesPieces() or @takesPieces())
    not move? or testPieceTaking and (move.score < @score or move.score == @score and Math.random() > 0.5)

  takesPieces: ->
    @hops.length != 0

  toString: ->
    "#{@from} #{@hops.join(' ')} #{@to}"


api =
  Colour: Colour
  KeyType : KeyType
  Piece : Piece,
  King : King,
  Square :Square,
  DraughtsBoard : DraughtsBoard,
  ComputerPlayer : ComputerPlayer,
  Move : Move

if exports?
  module.exports = api
else
  window.Draughts = api


