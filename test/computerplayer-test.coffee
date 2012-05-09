require "should"
draughts = require('../lib/draughts')


describe "#ComputerPlayer", ->

  black = draughts.Colour::BLACK
  white = draughts.Colour::WHITE

  describe "#move", ->

    it "always take a piece if we can", ->

      board = new draughts.DraughtsBoard((_) ->
          @black _.b, 3, _.a, 6, _.a, 2
          @white _.b, 1
      )

      player = new draughts.ComputerPlayer(board, black)
      player.move().toString().should.equal("a,2 b,1 c,0")

    it "should take multiple pieces if possible to do so", ->

      board = new draughts.DraughtsBoard((_) ->
          @black _.a, 4, _.h, 3
          @white _.b, 3, _.b, 1, _.g, 2
      )

      player = new draughts.ComputerPlayer(board, black)
      player.move().toString().should.equal("a,4 b,1 b,3 a,0")


    it "where multiple pieces can be taken, pick the best one", ->

      board = new draughts.DraughtsBoard((_) ->
          @black _.a, 4, _.h, 3
          @white _.a, 0, _.b, 3, _.b, 1, _.g, 2
      )

      player = new draughts.ComputerPlayer(board, black)
      player.move().toString().should.equal("h,3 g,2 f,1")

