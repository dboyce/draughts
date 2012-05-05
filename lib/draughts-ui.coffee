$(document).ready ->

  class PieceModel extends Backbone.Model

    initialize: ->
      @piece = @get('piece')


  class SquareModel extends Backbone.Model

    initialize: ->
      @square = @get('square')
      @board = @get('board')
      @row = @square.row
      @col = @square.col

    getTargetSquares: ->
      ret = []
      if @square.piece?
        for vector in @square.piece.vectors
          square = @board.getSquareView(vector[0] + @row, vector[1] + @col)
          ret.push(square) if square? and square.model.square.isEmpty()
      ret

  class BoardModel extends Backbone.Collection
    model: SquareModel

    initialize: ->
      @board = new DraughtsBoard()
      @squareModels = {}
      @board.listener = @
      @pieceViews = {}

    remove: (piece) ->
      @pieceViews[piece].remove()

    move: (piece, to) ->
      @pieceViews[piece].move(to)

    populate: ->
      try
        @board.publish = false
        @board.initGame()
        @add(square:square,board:@) for square in row for row in [].concat(@board.squares).reverse()
        for piece in [].concat(@board.pieces[white],@board.pieces[black]) when piece.square?
         pieceView = new PieceView(model:new PieceModel(piece:piece),appView:@appView)
         pieceView.move(piece.square)
         @pieceViews[piece] = pieceView
      finally
        @board.publish = true


  class PieceView extends Backbone.View

    tagName: 'div'

    attributes: ->
      "class" : "piece #{@model.piece.colour.name.toLowerCase()}"

    initialize: ->
      @piece = @model.piece
      @appView = @options.appView

    remove: ->
      $(@el).remove()

    move: (square) ->
      $(@el).detach()
      @square = square
      @appView.getSquareView(@square.row ,@square.col).setPiece(@)

  class SquareView extends Backbone.View
    tagName: "div"

    attributes: ->
      "class" : "square #{@model.square.colour.name.toLowerCase()}"

    setPiece: (piece) ->
      $(@el).children().remove()
      $(@el).append(piece.el)

    render: ->
      @

  class AppView extends Backbone.View
    tagName: 'div'

    attributes:
      "class" : "board"

    initialize: ->
      @squareCount = 0
      @el = $('div#board')
      @squareViews = {}
      @board = new BoardModel()
      @board.appView = @
      @board.bind('add', this.addSquare)
      @board.populate()


    addSquare: (model) =>
      @row = $("<div class='row'></div>").appendTo($(@el)) if @squareCount++ % 8 is 0
      view = new SquareView(model:model)
      $(@row).append(view.render().el)

      square = model.square
      row = @squareViews[square.row]
      unless row
        row = {}
        @squareViews[square.row] = row
      row[square.col] = view

    getSquareView: (row,col) ->
      @squareViews[row]?[col]


  appView = new AppView()
  player = new ComputerPlayer(appView.board.board, white)
  player2 = new ComputerPlayer(appView.board.board, black)
  whitesTurn = true

  main = ->
    move = if whitesTurn then player.move() else player2.move()
    whitesTurn = not whitesTurn
    move.take()
    setTimeout(main, 2000)

  main()



