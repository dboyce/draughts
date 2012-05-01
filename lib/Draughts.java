import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Draughts {
    
    public static void main(String[] args) {


        DraughtsBoard board = new DraughtsBoard().initGame();

        ComputerPlayer black1 = new ComputerPlayer(board, Colour.BLACK);
        Player whi1te = new CommandLinePlayer(board, Colour.WHITE);

        for(int i = 0; i < 100; i++) {

            System.err.println(board.toString());

            try {Thread.sleep(100);}
            catch (Exception e) {throw new RuntimeException(e); }

            Move move = whi1te.move();
            if(move != null)
                move.take();

            System.err.println("white: " + move);

            move = black1.move();
            if(move != null)
                move.take();

            System.err.println("black: " + move);
        }

    }
    
    private static final BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
    
    private static void pause() {
        try { reader.readLine(); }
        catch (Exception e) { throw new RuntimeException(e); }
    } 

    public enum Colour {
        BLACK,WHITE;
        
        public Colour flip() { return BLACK.equals(this)? WHITE : BLACK; }
    }
    
    public static class Piece {

        private DraughtsBoard board;
        private Colour colour;
        private Square square;
        private int[][] vectors;

        public Piece(Colour colour, DraughtsBoard board) {
            this.colour = colour;
            this.board = board;
            int deltaI = colour.equals(Colour.BLACK) ? 1 : -1;
            this.vectors = new int[][]{{deltaI, -1},{deltaI, 1}};
            this.getBoard().getPieces(colour).add(this);
        }

        public Colour getColour() { 
            return colour; 
        }
        
        public Square getSquare() { 
            return square; 
        }
        
        public void setSquare(Square square) {
            this.square = square;            
        }

        public int[][] getVectors() {
            return vectors;
        }
        
        protected void setVectors(int[][] vectors) {
            this.vectors = vectors;
        }               

        public DraughtsBoard getBoard() {
            return board;
        }
        
        public int getValue() {
            return 1;
        }

        public boolean isKinged() {
            return square!= null && colour.equals(Colour.BLACK) && square.getI() == 7 || square.getI() == 0;
        }
    }
    
    public static class King extends Piece {
        
        public King(Colour colour, DraughtsBoard board) {
            super(colour, board);
            this.setVectors(new int[][]{{1,-1},{1,1},{-1,1},{-1,1}});
        }

        @Override
        public int getValue() {
            return 2;
        }

        @Override
        public boolean isKinged() {
            return false;
        }
    }
    
    public static class Square {
        
        public static final char[] ROWS = {'a','b','c','d','e','f','g','h'};
        private final int i,j;
        private Colour color;        
        private Piece piece;

        public Square(int i, int j, Colour color) {

            this.i = i;
            this.j = j;
            this.color = color;
        }

        public Piece getPiece() { 
            return piece; 
        }
        
        public void setPiece(Piece piece) {
            if(piece == null && this.piece != null) {
                this.piece.setSquare(null);
            }
            this.piece = piece;
            if(piece != null) {
                if(piece.getSquare() != null) {
                    piece.getSquare().setPiece(null);
                }
                piece.setSquare(this);
            }
        }

        public Colour getColor() {
            return color;
        }
        
        public String toString() {
            return String.valueOf(ROWS[j]) + String.valueOf(i);
        }

        public int getI() {
            return i;
        }

        public int getJ() {
            return j;
        }
        
        public boolean isEmpty() {
            return this.piece == null;
        }
    }
    
    public static class DraughtsBoard {
        
        private Square[][] squares;
        private List<Piece> whitePieces = new ArrayList<Piece>(12);
        private List<Piece> blackPieces = new ArrayList<Piece>(12);
        
        public DraughtsBoard() {
            squares = new Square[8][8];
            for(int i = 0; i < squares.length; i++) {
                for(int j = 0; j < squares[i].length; j++) {
                    squares[i][j] = new Square(i, j, i % 2 == j % 2 ? Colour.BLACK : Colour.WHITE);
                }
            }
        }
        
        public DraughtsBoard initGame() {
            whitePieces.clear();;
            blackPieces.clear();
            for(int i = 0; i < squares.length; i++) {
                for(int j = 0; j < squares[i].length; j++) {
                    if(squares[i][j].getColor().equals(Colour.BLACK) && !(i == 3 || i == 4)) {
                        Piece piece = new Piece(i < 3 ? Colour.BLACK : Colour.WHITE, this);
                        squares[i][j].setPiece(piece);
                    }
                    else {
                        squares[i][j].setPiece(null);
                    }
                }
            }
            
            return this;
        }
        
        public Square getSquare(String square) {
            Pattern pattern = Pattern.compile("\\s*([a-h])([0-9])\\s*");
            Matcher matcher = pattern.matcher(square);
            if(matcher.matches()) {
                int i = Integer.parseInt(matcher.group(2));
                int j = matcher.group(1).charAt(0) - 'a';
                return getSquare(i,j);
            }
            else {
                return null;
            }
        }
        
        public List<Piece> getPieces(Colour colour) {
            return colour.equals(Colour.BLACK) ? blackPieces : whitePieces;
        }
        
        public String toString() {
            String rowSeparator = "--------" + "---------";
            StringBuilder builder = new StringBuilder(rowSeparator).append("\n");
            for(int i = 7; i > -1; i--) {         
                for(int j = 0; j < 8; j++) {
                    Piece piece = squares[i][j].getPiece();
                    String name = piece == null ? null : piece.getColour().name().substring(0, 1);
                    builder.append("|").append(piece == null ? (squares[i][j].getColor().equals(Colour.BLACK) ? "*" : ' ')
                            : (piece instanceof King ? name : name.toLowerCase()));
                }
                builder.append("|\n").append(rowSeparator).append("\n");
            }
            return builder.toString();
        }
        
        public Square getSquare(int i, int j) {
            return check(i) && check(j) ? squares[i][j] : null;
        }
        
        private boolean check(int i) {
            return i < 8 && i > -1;
        }
    } 
    
    public static interface Player {
        Move move();
    }
    
    public static class CommandLinePlayer implements Player {
        
        private BufferedReader reader = new BufferedReader(new InputStreamReader(System.in));
        private DraughtsBoard board ;
        private Colour colour;

        public CommandLinePlayer(DraughtsBoard board, Colour colour) {
            this.board = board;
            this.colour = colour;
        }

        @Override
        public Move move() {
            try {

                System.out.print("type move: ");

                String s = reader.readLine();
                String[] string = s.split("to");

                Square from = board.getSquare(string[0]);
                Square to = board.getSquare(string[1]);

                if(from == null || to == null) {
                    System.out.println("\ncouldn't understand: " + s);
                    return move();
                }
                else if(from.getPiece() == null || !from.getPiece().getColour().equals(colour)) {
                    System.out.println("\nno " + colour + " piece at: " + from);
                    return move();
                }
                else if(!to.getColor().equals(Colour.BLACK) || !canMove(from.getPiece(), to)) {
                    return move();
                }
                
                return new Move(from.getPiece(), from, to, 1);
                                
            }
            catch (Exception e) {
                throw new RuntimeException(e);
            }            
        }
        
        private boolean canMove(Piece piece, Square square) {
            int deltaI = square.getI() - piece.getSquare().getI();
            int deltaJ = square.getJ() - piece.getSquare().getJ();
            
            for(int[] vector : piece.getVectors()) {
                if(deltaI == vector[0] && deltaJ == vector[1]) {
                    return true;
                }
            }
            
            return false;
                    
        }
    }
    
    public static class ComputerPlayer {
        
        private int maxDepth = 2;
        private DraughtsBoard board;
        private Colour colour;
        private Set<Piece> takenPieces = new HashSet<Piece>();

        public ComputerPlayer(DraughtsBoard board, Colour colour) {
            this.board = board;
            this.colour = colour;
        }
        
        public Move move() {
            try { return pickMove(board.getPieces(colour), board.getPieces(colour.flip()), colour, 0, false, 0); }
            finally { takenPieces.clear(); }
        }
        
        private Move pickMove(List<Piece> pieces, List<Piece> opponentPieces, Colour colour, int depth, boolean hopping, int score) {
            Move bestMove = null;
            for(Piece piece : pieces) {

                if(takenPieces.contains(piece)) { continue; }

                Square fromSquare = piece.getSquare();
                for(int[] vector : piece.getVectors()) {
                    Move current = null;                    
                    Square toSquare = board.getSquare(fromSquare.getI() + vector[0], fromSquare.getJ() + vector[1]);
                    if(!isCanMove(toSquare, colour)) {
                        // can't move here..
                        continue;
                    }
                    else if(!toSquare.isEmpty()) {

                        Square jumpTo = board.getSquare(toSquare.getI() + vector[0], toSquare.getJ() + vector[1]);
                        if(jumpTo == null || !jumpTo.isEmpty()) {
                            // can't take piece
                            continue;
                        }
                        Piece takenPiece = toSquare.getPiece();
                        toSquare.setPiece(null);
                        takenPieces.add(takenPiece);
                        jumpTo.setPiece(piece);

                        if(piece.isKinged()) {
                            // we've been kinged... so
                            current = new Move(piece, fromSquare, jumpTo, score + takenPiece.getValue());
                            if(depth < maxDepth) {
                                Move counterMove = pickMove(board.getPieces(colour.flip()), board.getPieces(colour),
                                        colour.flip(), depth + 1, false, 0);
                                current.setScore(current.getScore() - (counterMove == null ? 0 : counterMove.getScore()));
                            }
                        }
                        else {
                            // can we hop this piece further...
                            current = pickMove(Arrays.asList(piece),
                                    opponentPieces, colour, depth, true, score + takenPiece.getValue());

                            if(current == null) {
                                current = new Move(piece, fromSquare, jumpTo, score + takenPiece.getValue());
                            }
                        }

                        if(current.getHops().isEmpty())
                            current.setTo(jumpTo);

                        current.setFrom(fromSquare);
                        current.getHops().add(0, toSquare);

                        toSquare.setPiece(takenPiece);
                        fromSquare.setPiece(piece);
                        takenPieces.remove(takenPiece);

                    }
                    else {

                        // if we were hopping (taking pieces) this was our last hop
                        current = new Move(piece, fromSquare, hopping ? fromSquare : toSquare, 
                                piece.isKinged() ? score + 2 : score);
                        
                        if(depth < maxDepth) {

                            if(toSquare.getPiece() != null) {
                                throw new RuntimeException("arrrgghh!!!");
                            }
                            toSquare.setPiece(piece);

                            Move counterMove = pickMove(
                                    board.getPieces(colour.flip()),
                                    board.getPieces(colour), colour.flip(), depth + 1, false, 0);
                            current.setScore(current.getScore() - (counterMove == null ? 0 : counterMove.getScore()));

                            fromSquare.setPiece(piece);
                        }
                    }

                    if(bestMove == null 
                            || current.isTakePieces() && !bestMove.isTakePieces() 
                            || current.getScore() > bestMove.getScore() && 
                                (!bestMove.isTakePieces() || current.isTakePieces())) {
                        bestMove = current;
                    }
                }
            }
            
            return bestMove;
        }

        private boolean isCanMove(Square square, Colour colour) {
            return !(square == null || !square.isEmpty() && square.getPiece().getColour().equals(colour));
        }

    }   
    
    
    public static class Move {
        private Piece piece;
        private Square from;
        private Square to;
        private List<Square> hops = new ArrayList<Square>();
        private int score;
        private boolean takePieces = false;

        public Move(Piece piece, Square from, Square to, int score) {
            this.piece = piece;
            this.from = from;
            this.to = to;
            this.score = score;
        }
        
        public void take() {
            if(!hops.isEmpty()) {
                List<Piece> opponentPieces = piece.getBoard().getPieces(piece.getColour().flip());
                for(Square hop : hops) {
                    opponentPieces.remove(hop.getPiece());
                    hop.setPiece(null);
                }
                to.setPiece(piece);
            }
            else {
                to.setPiece(piece);
            }

            if(piece.isKinged()) {
                piece.getBoard().getPieces(piece.getColour()).remove(piece);
                King king = new King(piece.getColour(), piece.getBoard());
                king.setSquare(piece.getSquare());
                this.piece = king;
            }
        }

        public Piece getPiece() {
            return piece;
        }

        public void setPiece(Piece piece) {
            this.piece = piece;
        }

        public Square getFrom() {
            return from;
        }

        public void setFrom(Square from) {
            this.from = from;
        }

        public Square getTo() {
            return to;
        }

        public void setTo(Square to) {
            this.to = to;
        }

        public List<Square> getHops() {
            return hops;
        }

        public void setHops(List<Square> hops) {
            this.hops = hops;
        }

        public int getScore() {
            return score;
        }

        public void setScore(int score) {
            this.score = score;
        }

        public boolean isTakePieces() {
            return takePieces;
        }

        public void setTakePieces(boolean takePieces) {
            this.takePieces = takePieces;
        }

        public String toString() {
            if(hops.isEmpty()) {
                return from + " to " + to;
            }
            else {
                StringBuilder builder = new StringBuilder(from.toString()).append(" to ");
                for(Square hop : hops) {
                    builder.append(hop).append(" to ");
                }
                builder.append(to.toString());
                return builder.toString();
            }
        }
    }   
    
    
}
