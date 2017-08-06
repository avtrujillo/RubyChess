# the word "bug" in comments will be used to flag unfixed bugs

$rubychess_dir = __dir__

$neg_display = true # controls whether or not to invert the black and white colors in the display

require_relative('./Ordinals')
require 'yaml'
require 'byebug'

require_relative './modules/chessdir'
require_relative './modules/userprompt'
require_relative './modules/simulations'
require_relative './classes/scoreboard'
require_relative './classes/coordinates'
require_relative './classes/game'
require_relative './classes/snapshot'
require_relative './classes/tempstate'
require_relative './classes/boardstate'
require_relative './classes/simlevel'
require_relative './classes/path.rb'
require_relative './classes/castlepath.rb'
require_relative './classes/piece.rb'
require_relative './classes/rook.rb'
require_relative './classes/bishop.rb'
require_relative './classes/knight.rb'
require_relative './classes/queen.rb'
require_relative './classes/king.rb'
require_relative './classes/pawn.rb'
require_relative './classes/tile.rb'
require_relative './classes/team.rb'
require_relative './classes/player.rb'
require_relative './classes/move.rb'
require_relative './classes/turnmenu.rb'
require_relative './classes/mainmenu.rb'

$coordinates = []

OPENING_MOVES = [ #for debugging
	["A2", "A3"], ["A2, A4"], ["B2", "B3"], ["B2", "B4"], ["C2", "C3"],
	["C2", "C4"], ["D2", "D3"], ["D2", "D4"], ["E2", "E3"], ["E2", "E4"],
	["F2", "F3"], ["F2", "F4"], ["G2", "G3"], ["G2", " G4"], ["H2", "H3"],
	["H2", "H4"], ["B1", "A3"], ["B1", "C3"], ["G1", "F3"], ["G1", "H3"]
]

def valid_opening?(opening) #for debugging
	formatted_opening = [opening.departure.coordinates.name, opening.destination.coordinates.name]
	return OPENING_MOVES.include?(formatted_opening)
end




def in_between(a, b)
	in_between_list = []
	if a > b
		for x in ((b + 1)...a)
			in_between_list.push(x)
		end
	elsif b > a
		for x in ((a + 1)...b)
			in_between_list.push(x)
		end
	end
	return in_between_list
end

=begin

The board is a two-dimensional array of all tiles that
is only used in the board_display function. The tiles array
is a flattened version of the board, which is easier to look
up individual tiles from using the .find method. Only the main
boardstate has a board as an attribute, simlevels don't need
them as they are never displayed. Tile arrays exists as an
attribute of both the main boardstate and all simlevels.

=end



=begin
To explain how the display works: each tile is a 3x3 arrangement of unicode
characters, the middle of which is the piece icon:

■■■
■♖■
■■■

It, uh, looks a lot better in command prompt, just trust me.
Anyway, the top three characters are called the "bread", as are the bottom
three. The "meat" is the middle three (think of a sandwich). So:

bread
meat
bread

When we print out the display, we combine all the breads of the tiles in a
given row to make onelong string, then do the same for the meat. Then, for each
row we print out bread, then meat on the next line, then bread again on the
next, like so:

A1bread B1bread C1bread D1bread E1bread F1bread G1bread H1bread
A1meat  B1meat  C1meat  D1meat  E1meat  F1meat  G1meat  H1meat
A1bread B1bread C1bread D1bread E1bread F1bread G1bread H1bread

We do this for each row, then also add axes and legends where appropriate.

=end

if $needs_testing == true # this step is ony for debugging
	$test_protocol
end

MainMenu.new
