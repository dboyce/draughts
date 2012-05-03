$(document).ready ->

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

    populate: ->
      @board.initGame()
      @add(square:square,board:@) for square in row for row in [].concat(@board.squares).reverse()

    getSquareView: (row,col) ->
      @appView.getSquareView(row,col)

  class SquareView extends Backbone.View
    tagName: "div"

    attributes: ->
      "class" : "square #{@model.square.colour.name.toLowerCase()}"

    events:
      "mousedown" : "showMoves",
      "mouseup" : "unShowMoves"

    showMoves: ->
      unless @model.square.isEmpty()
        @highlighted = @model.getTargetSquares()
        square.highlight() for square in @highlighted


    unShowMoves: ->
      if @highlighted?
        square.unhighlight() for square in @highlighted
        @highlighted = null

    highlight: ->
      $(@el).addClass('highlighted')

    unhighlight: ->
      $(@el).removeClass('highlighted')

    render: ->
      unless @model.square.isEmpty()
        $(@el).html("<div class='piece #{@model.square.piece.colour.name.toLowerCase()}'></div>")
      else
        $(@el).html('')
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
      @board.bind('add', this.addSquare)
      @board.populate()
      @board.appView = @

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




  new AppView()
