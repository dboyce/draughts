$(document).ready ->

  class SquareModel extends Backbone.Model

    events:
      "click" : "showMoves"

    initialize: ->
      @square = @get('square')

    showMoves: ->
      unless @square.isEmpty()
        console.log('show moves...')



  class BoardModel extends Backbone.Collection
    model: SquareModel

    initialize: ->
      @board = new DraughtsBoard()

    populate: ->
      @board.initGame()
      @add(square:square) for square in row for row in [].concat(@board.squares).reverse()

  class SquareView extends Backbone.View
    tagName: "div"

    attributes: ->
      "class" : "square #{@model.square.colour.name.toLowerCase()}"

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
      @board = new BoardModel()
      @board.bind('add', this.addSquare)
      @board.populate()

    addSquare: (square) =>
      @row = $("<div class='row'></div>").appendTo($(@el)) if @squareCount++ % 8 is 0
      $(@row).append(new SquareView(model:square).render().el)

  new AppView()
