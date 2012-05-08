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

      if piece.colour is white
        @trigger('move')

    addPiece: (piece) ->
      view = new PieceView(model:new PieceModel(piece:piece),appView:@appView)
      @pieceViews[piece] = view
      dragDrop.addDraggable(view.el) if piece.colour is white


    populate: ->
      @add(square:square,board:@) for square in row for row in [].concat(@board.squares).reverse()
      @board.initGame()


  class PieceView extends Backbone.View

    tagName: 'div'

    attributes: ->
      "class" : "piece #{@model.piece.colour.name.toLowerCase()} #{if @model.piece instanceof King then 'king' else ''}"

    initialize: ->
      @piece = @model.piece
      @appView = @options.appView
      @king = @piece instanceof King
      if @king
        $(@el).append("K")
      $(@el).data('piece', @)

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
      dragDrop.addDropTarget(view.el, (el) =>
        pieceView = $(el).data('piece')
        throw "couldn't locate piece for: #{el}" unless pieceView?
        move = pieceView.piece.getMove(model.square)
        if move?
          move.take()
          return true
        else
          return false
      )

      square = model.square
      row = @squareViews[square.row]
      unless row
        row = {}
        @squareViews[square.row] = row
      row[square.col] = view

    getSquareView: (row,col) ->
      @squareViews[row]?[col]


  dragDrop = new DragNDropManager()
  appView = new AppView()


  computer = new ComputerPlayer(appView.board.board, black)

  appView.board.on('move', ->
      try
        dragDrop.dragDisabled = true
        computer.move().take()
      finally
        dragDrop.dragDisabled = false
  )




