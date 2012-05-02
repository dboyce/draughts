draughts = require "../lib/draughts"

board = new draughts.DraughtsBoard().initGame()
white = new draughts.ComputerPlayer(board, draughts.Colour::WHITE)
black = new draughts.ComputerPlayer(board, draughts.Colour::BLACK)


for i in [1..20]
  white.move().take()
  black.move().take()

console.log board.toString()