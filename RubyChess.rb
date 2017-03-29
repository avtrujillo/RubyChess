# the word "bug" in comments will be used to flag unfixed bugs
$needs_testing = false #used for debugging

$neg_display = true # controls whether or not to invert the black and white colors in the display

$pvp_scoreboard = [0, 0]
$AI_scoreboard = [0, 0]

$players = []

$pos_piece_symbols = {
	"white king" => "♔",
	"white queen" => "♕",
	"white rook" => "♖",
	"white bishop" => "♗",
	"white knight" => "♘",
	"white pawn" => "♙",
	"black king" => "♚",
	"black queen" => "♛",
	"black rook" => "♜",
	"black bishop" => "♝",
	"black knight" => "♞",
	"black pawn" => "♟"
}

$neg_piece_symbols = {
	"white king" => "♚",
	"white queen" => "♛",
	"white rook" => "♜",
	"white bishop" => "♝",
	"white knight" => "♞",
	"white pawn" => "♟",
	"black king" => "♔",
	"black queen" => "♕",
	"black rook" => "♖",
	"black bishop" => "♗",
	"black knight" => "♘",
	"black pawn" => "♙"
}

$legend_key = $neg_piece_symbols.sort
$legend_numbered = $legend_key.each_slice(3).to_a

def neg_display_initiate #black becomes white and white becomes black
	$piece_symbols = $neg_piece_symbols
	$black_square = "□"
	$white_square = "■"
	$legend_key = $neg_piece_symbols.sort
	$legend_numbered = $legend_key.each_slice(3).to_a
end

def pos_display_initiate #black becomes black and white becomes white
	$piece_symbols = $pos_piece_symbols
	$black_square = "■"
	$white_square = "□"
	$legend_key = $pos_piece_symbols.sort
	$legend_numbered = $legend_key.each_slice(3).to_a
end

def display_negativity_update
	if $neg_display == true
		neg_display_initiate
	else
		pos_display_initiate
	end
end

def negativity_flip
	$neg_display = !$neg_display
	display_negativity_update
end

display_negativity_update

def negquery
	board = board_create #note: got rid of board_fill because there was no game to use as an argument and we don't need the board to be filled anyway
	board_display(board)
	negdone = false
	if $first_negquery == true
		puts "Hi, welcome to chess! Before we begin I need your help to set the display.\n"
	end
	until negdone == true #keeps going until the user is satisfied with the appearance of the display
		puts "In the above board, does tile A1 appear black to you?\n"
		response = gets.chomp
		if response.downcase == "yes"
			if $first_negquery == true
				puts "\nGood. Let's get started then."
				$first_negquery = false
			end
			negdone = true
		elsif response.downcase == "no"
			negativity_flip
			board = board_create #note: got rid of board_fill because there was no game to use as an argument and we don't need the board to be filled anyway
			board_display(board)
			"How about now?"
		else
			puts "Sorry, I didn't understand that."
		end
	end
end

def x_to_letter(x_axis) #converts x coordinates to letters
	$alph = ["taken", "A", "B", "C", "D", "E", "F", "G", "H"] # used to translate between letter and row number
	letter = $alph[x_axis]
	return letter
end

def letter_to_x(letter) #converts letters to x coordinates
	x_axis = $alph.index(letter)
	return x_axis
end

def alphanum_to_num(text) #for converting e.g. "A1" to "(1, 1)"
	letter = text.chop.downcase #isolates the letter in the coordinates
	y_axis = text.reverse.chop.to_i #isolates the y-coordinate
	x_axis = letter_to_x(letter) #translates the letter to an x-coordinate
	output = [x_axis, y_axis]
	return output
end

def num_to_alphanum(x_axis, y_axis) #for converting e.g. "(1, 1)" to "A1"
	letter = x_to_letter(x_axis) #translates the x-coordinate to a letters
	alphanum = letter + y_axis.to_s #combines the letter and y-coordinate to create a single name
	return alphanum
end

class Game
	attr_accessor :simlevels, :white_player, :black_player, :white_team, :black_team, :name, :history, :pieces, :board, :tiles, :moving_team, :boardstate
	def initialize(white_player, black_player)
		@white_player = white_player
		@black_player = black_player
		@black_team = Team.new("black", @black_player, self)
		@white_team = Team.new("white", @white_player, self)
		@pieces = starting_pieces(self)
		@board = board_create #the "board" attribute is a two-dimensional array of all tiles that is only used in the board_display function
		@tiles = @board.flatten
		board_fill(@board, @pieces)
		@moving_team = @white_team
		@simlevels = []
		@boardstate = Boardstate.new(self, @tiles, @pieces, 0)
		@simlevels.push(self.boardstate)
		@simlevels.push(Simlevel.new(self, [], 0))
		@simlevels.push(Simlevel.new(self, [], -1))
		@name = nil #to be used when saving and loading games
		@history = []
		#gonna try moving the line commented out below to game.play
		#@boardstate.movelist = generate_valid_moves(@boardstate)
	end
	def play
		generate_valid_moves(@boardstate)
		$playing = true #reminder: make sure this updates when ending or saving a game
		until $playing == false
			turn_prompt(self.boardstate)
		end
	end
	def exit_game
		save = nil
		valid_response = false
		until valid_response == true
			puts "Would you like to save?"
			response = gets.chomp.downcase
			if response == "yes"
				save = true
				valid_response = true
			elsif response == "no"
				save = false
				valid_response = true
			else
				puts "Sorry, I didn't understand that."
			end
		end
		if save == true
			#unfinished
		end
		$playing = false
	end
end

class Snapshot
	attr_accessor :team_to_move, :move, :fossils, :turn_counter
	def initialize(boardstate)
		@team_to_move = boardstate.moving_team
		@move = boardstate.move
		@turn_counter = boardstate.turn_counter
		@fossils = Hash.new #records of the pieces and their positions on the board
		@special_move_opportunities = []
		boardstate.tiles.each do |tile| #I chose to do this with the tiles array rather than the pieces array because the order of the former never changes, and we want to be able to check whether the hashes are identical
			@fossils[tile.occupied_piece.title] = tile.occupied_piece.coordinates
			if (((tile.occupied_piece.rank == "rook") && (tile.occupied_piece.can_castle == true)) || ((tile.occupied_piece.rank == "pawn") && (boardstate.game.history.last.destination == tile) && ((boardstate.game.history.last.departure.y_axis - tile.y_axis).abs == 2)))
				@special_move_opportunities.push(tile)
			end
		end
	end
end

class Boardstate #redundant, but makes things easier to read
	attr_accessor :game, :tiles, :pieces, :depth, :turn_counter, :white_king, :black_king, :moving_team, :fifty_move_counter, :game_over, :movelist
	def initialize(game, tiles, pieces, depth = 0)
		@game = game
		@tiles = tiles #remember, these are to reflect only the attributes of the game at the time of creation
		@pieces = pieces
		@depth = depth
		@turn_counter = 0
		@white_king = @pieces.find {|piece| piece.title == "white king"}
		@black_king = @pieces.find {|piece| piece.title == "black king"}
		@moving_team = @game.moving_team
		@fifty_move_counter = 0
		@game_over = false #reminder: do we need this? If so, should it be moved to game instead?
		@movelist = [] #list of all possible valid moves for the next turn
	end
	def friendly_king
		if self.moving_team == self.game.white_team
			return self.white_king
		else return self.black_king
		end
	end
	def enemy_king
		if self.moving_team == self.game.white_team
			return self.black_king
		else return self.white_king
		end
	end
	def go_deeper
		sublevel = game.simlevels.find {|level| level.depth == (@depth - 1)}
		return sublevel
	end
	def simulate
		deeper = Simlevel.new(self.game, self.tiles, self.depth)
		if ((self.game.simlevels.count < (self.depth.abs + 2)) && (self.game.simlevels.count >= 3))
			self.game.simlevels.push(deeper)
		elsif self.game.simlevels.count >= (self.depth.abs + 2)
			self.game.simlevels[self.depth.abs + 1] = deeper
		end
		return deeper
	end
	def record
		return Snapshot.new(self)
	end
	def taken_pieces
		return pieces.select {|piece| piece.coordinates == nil}
	end
end


class Simlevel < Boardstate #used for check_detect and checkmate_detect
	def initialize(game, supertiles = [], superdepth) #the "super" prefix means that something is from the level above the one being created
		@game = game
		@tiles = []
		@pieces = []
		supertiles.each do |supertile|
			simtile = supertile.simulate
			@tiles.push(simtile)
			unless simtile.occupied_piece == nil
				@pieces.push(simtile.occupied_piece)
			end
		end
		@moving_team = @game.moving_team
		@white_king = @pieces.find {|piece| piece.title == "white king"}
		@black_king = @pieces.find {|piece| piece.title == "black king"}
		@depth = (superdepth - 1) #how many levels of simulation deep are we?
		@turn_counter = game.boardstate.turn_counter
		@fifty_move_counter = game.simlevels[superdepth].fifty_move_counter
		@game_over = false
		@movelist = []
	end
	def go_deeper
		sublevel = game.simlevels.find {|level| level.depth == (@depth - 1)}
		return sublevel
	end
	def wake_up #think "Inception"
		superlevel = game.simlevels.find {|level| level.depth == (@depth + 1)}
		return superlevel
	end
	def simulate
		super
	end
	def friendly_king
		super
	end
	def enemy_king
		super
	end
end

$opening_moves = [ #for debugging
	["A2", "A3"], ["A2, A4"], ["B2", "B3"], ["B2", "B4"], ["C2", "C3"],
	["C2", "C4"], ["D2", "D3"], ["D2", "D4"], ["E2", "E3"], ["E2", "E4"],
	["F2", "F3"], ["F2", "F4"], ["G2", "G3"], ["G2", " G4"], ["H2", "H3"],
	["H2", "H4"], ["B1", "A3"], ["B1", "C3"], ["G1", "F3"], ["G1", "H3"]
]

def valid_opening?(opening) #for debugging
	formatted_opening = [opening.departure.coordinates.name, opening.destination.coordinates.name]
	return $opening_moves.include?(formatted_opening)
end

class Coordinates
	attr_accessor :x_axis, :y_axis, :letter, :name
	def initialize(text)
		@letter = text.chop.upcase #isolates the letter in the coordinates
		@y_axis = text.reverse.chop.to_i #isolates the y-coordinate
		@x_axis = letter_to_x(@letter) #changes the letter to a row number
		@name = text
		$coordinates.push(self)
	end
end

$coordinates = []

class Piece
	attr_accessor :rank, :coordinates, :title, :name, :serial, :depth, :game, :simlevel, :moved, :color
	def initialize(rank, color, tilename, serial, game, depth = 0)
		@depth = depth
		@rank = rank
		@color = color
		@coordinates = $coordinates.find {|coordinate| coordinate.name == tilename.upcase}
		@title = color + " " + @rank
		@serial = serial
		@name = color + "_" + @rank + "_" + serial.to_s
		@game = game
		@moved = false
	end
	def simlevel
		return self.game.simlevels[self.depth.abs]
	end
	def team
		if color == "black"
			return self.game.black_team
		else
			return self.game.white_team
		end
	end
	def tile
		return (self.simlevel.tiles.find {|tile| tile.coordinates == self.coordinates})
	end
	def x_path # all the possible moves of a bishop
		nw_path = []
		ne_path = []
		se_path = []
		sw_path = []
		compass = [[-1, 1, nw_path], [1, 1, ne_path], [1, -1, se_path], [-1, -1, sw_path]]
		direction = 0
		x_coordinate = self.coordinates.x_axis
		y_coordinate = self.coordinates.y_axis
		path = nw_path
		path_end = false
		loop do
			x_coordinate += compass[direction][0]
			y_coordinate += compass[direction][1]
			step = self.simlevel.tiles.find {|tile| ((tile.coordinates.x_axis == x_coordinate) && (tile.coordinates.y_axis == y_coordinate))}
			if step == nil || (path_end == true)
				direction += 1
				break if direction > 3
				path = compass[direction][2]
				x_coordinate = self.coordinates.x_axis
				y_coordinate = self.coordinates.y_axis
				path_end == false
			elsif step.occupied_piece == nil
				path.push(step)
			elsif step.occupied_piece.team == self.team
				direction += 1
				break if direction > 3
				path = compass[direction][2]
				x_coordinate = self.coordinates.x_axis
				y_coordinate = self.coordinates.y_axis
				path_end == false
			else
				path_end = true
				path.push(step)
			end
		end
		return (nw_path + ne_path + se_path + sw_path)
	end
	def plus_path #all the possible moves of a rook
		north_path = []
		east_path = []
		south_path = []
		west_path = []
		compass = [[0, 1, north_path], [1, 0, east_path], [0, -1, south_path], [-1, -1, west_path]]
		# we need to check each direction: north, south, east, and west
		# for each entry, the number at [0] will be added to the x_coordinate each turn
		# similarly, the number at [1] will be added to the y_coordinate each turn
		direction = 0
		x_coordinate = self.coordinates.x_axis
		y_coordinate = self.coordinates.y_axis
		path = north_path
		path_end = false # this is used to indicated that we have reached an enemy
		# piece, and cannot move any further
		loop do
			# we proceed stepwise, evaluating whether the step is a valid destination
			# when we reach an invalid destination, we repeat in a different direction
			# until we've checked all four directions
			x_coordinate += compass[direction][0]
			y_coordinate += compass[direction][1] #this is where we take a step
			# the next line retrieves the tile we have just moved to
			step = self.simlevel.tiles.find {|tile| ((tile.coordinates.x_axis == x_coordinate) && (tile.coordinates.y_axis == y_coordinate))}
			if step == nil || path_end == true
				# if we can't find the tile we stepped on in the list of tiles, that
				# means that we have stepped off the board
				direction += 1 # we move on to the next direction
				break if direction > 3 # unless we have already checked all of them
				path = compass[direction][2]
				x_coordinate = self.coordinates.x_axis
				y_coordinate = self.coordinates.y_axis
				# we need move back to the current location of the moving piece before
				# checking a new direction
				path_end == false # we also have to reset this
			elsif step.occupied_piece == nil
				# if we have just stepped onto an empty tile, we add it to the list of
				# valid moves in the direction we are currently moving
				path.push(step)
			elsif step.occupied_piece.team == self.team
				# we cannot move onto a tile occupied by a friendly piece, so we need to
				# move on to the next direction
				direction += 1
				break if direction > 3
				path = compass[direction][2]
				x_coordinate = self.coordinates.x_axis
				y_coordinate = self.coordinates.y_axis
				path_end == false
			else # the only remaining possibility is that we have stepped onto a tile
				# that is occupied by an enemy piece. This means that while the current
				# step represents a valid destination, we have reached the end of the path
				path_end = true
				# setting path_end to true will, on the next iteration of the loop,
				# trigger the conditional that moves on to the next direction
				path.push(step)
			end
		end
		return (north_path + east_path + south_path + west_path)
	end
	def asterisk_path # these are the possible moves of a queen
		return (self.x_path + self.plus_path)
	end
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
Hey Ruby, suck each of my nuts with a value between one and two.
If you had created a way of making ranges exclusive for both end values, you could have gotten away with sucking zero nuts.
But no, now you are obligated to suck at least one nut as a direct result of your sins.
=end

#unfinished: fix the whole sim/deep clone fiasco (make it a single integer, etc)

class Rook < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("rook", team, tilename, serial, game, depth)
	end
	def simulate
		simpiece = Rook.new(self.color, self.coordinates.name, self.serial, self.game, (self.depth - 1)) #the tile given as an argument should be the one with the same depth
		simpiece.moved = self.moved
		return simpiece
	end
	def can_castle
		tiles = self.game.simlevels[self.depth.abs].tiles #start with an array of all the tiles in the current simlevel
		king = self.team.kings[self.depth.abs]
		both_unmoved = false # have the king or rook or both been moved yet?
		both_unmoved = true if (self.moved == (false) && (king.moved == false))
		clear_path = true #are there any pieces between the king and rook?
		intermediate_tiles = tiles.select {|tile| tile.coordinates.y_axis == self.coordinates.y_axis} #we only care about tiles in the same row as the king and rook
		intermediate_tiles.select! {|tile| in_between(self.coordinates.x_axis, king.coordinates.x_axis).include?(tile.coordinates.y_axis)}
		intermediate_tiles.each do |tile|
			if tile.occupied_piece != nil
				clear_path = false
			end
		end
		safe_path = true #would the king be in check on any of the tiles it moves through?
		kingpath_tiles = intermediate_tiles.select {|tile| tile.coordinates.x_axis.between?((king.coordinates.x_axis - 2), (king.coordinates.x_axis + 2))}
		kingpath_tiles.each do |tile|
			if Move.new(self.game, king.tile, tile).ally_check == true
				safe_path = false
			end
		end
		if ((safe_path == true) && (clear_path == true) && (both_unmoved == true) && ((self.game.history.empty? == true) || (self.game.history.last.enemy_check == false)))
			return true
		else
			return false
		end
	end
	def criteria(boardstate)
		plus_moves = self.plus_path
		boardstate.movelist.each do |move|
			if ((move.piece == self) && (plus_moves.include?(move.destination) == false))
				boardstate.movelist.delete(move)
			end
		end
		if ((self.depth > (-2)) && (self.can_castle == true)) #the former condition is in place to prevent infinite loops where check detect simulates castling as a possible move, which in turn must run check detect
			boardstate.movelist.push(Move.new(self.game, self.tile, "castle"))
		end
	end
	def castle_destination #where will this piece end up if it castles?
		if self.coordinates.name == "A1" #note: this will probably crash if self.can_castle == false
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "D1"}
		elsif self.coordinates.name == "A8"
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "D8"}
		elsif self.coordinates.name == "H1"
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "F8"}
		elsif self.coordinates.name == "H8"
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "F1"}
		end
	end
	def castle(move)
		move.previous_turn = move.game.history.last
		move.previous_turn.following_turn = move
		puts "#{move.team.color.capitalize} castles from #{move.departure.cordinates.name}."
		move.piece.coordinates = destination.coordinates
		move.destination.occupied_piece = move.piece
		move.departure.occupied_piece = nil
		king = move.game.boardstate.king
		king_destination = king.castle_destination(rook_departure)
		king_departure = king.tile
		king_destination.occupied_piece = king
		king_departure.occupied_piece = nil
		king.coordinates = king_destination.coordinates
		move.game.move_history.push(move) #reminder: should this happen before or after game over?
		move.game.boardstate.turn_counter += 1
		move.piece.moved = true
		move.game.boardstate.moving_team = move.team.opposite
		move.snapshot = Snapshot.new(move.game.boardstate)
		generate_valid_moves(move.game.boardstate)
		if (move.enemy_check == true) && (move.game.boardstate.movelist.find {|found_move| found_move.ally_check == false} == nil) #aka checkmate
			game_over(move, checkmate)
		elsif (move.enemy_check == false) && (move.game.boardstate.movelist.find {|found_move| found_move.ally_check == false} == nil)
			game_over(move, stalemate)
		end
		board_display(move.game.board)
		if (move.enemy_check == true)
			puts "#{move.enemy.capitalize}'s king is in check!"
		end
	end
end

class Knight < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("knight", team, tilename, serial, game, depth)
	end
	def simulate
		simpiece = Knight.new(self.color, self.coordinates.name, self.serial, self.game, (self.depth - 1)) #the tile given as an argument should be the one with the same depth
		simpiece.moved = self.moved
		return simpiece
	end
	def criteria(boardstate)
		piece_moves = boardstate.movelist.select {|move| move.piece == self}
		piece_moves.each do |move|
			x_difference = (move.destination.coordinates.x_axis - move.departure.coordinates.x_axis).abs
			y_difference = (move.destination.coordinates.y_axis - move.departure.coordinates.y_axis).abs
			unless (((x_difference - y_difference).abs == 1) && (x_difference + y_difference == 3))
				boardstate.movelist.delete(move) #this used to be piece_moves.delete(move)
				#but for some reason changing this and commenting out the section below
				#prevented the knights from deleting moves that weren't theirs
				#even though afaict there shouldn't have been any change in function
			end
		end
#		boardstate.movelist.each do |move|
#			if ((move.piece == self) && (piece_moves.include?(move) == false)
#				boardstate.movelist.delete(move))
#			end
#		end
	end
end

class Bishop < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("bishop", team, tilename, serial, game, depth)
	end
	def simulate
		simpiece = Bishop.new(self.color, self.tile.coordinates.name, self.serial, self.game, (self.depth - 1)) #the tile given as an argument should be the one with the same depth
		simpiece.moved = self.moved
		return simpiece
	end
	def criteria(boardstate)
		boardstate.movelist.each do |move|
			if ((move.piece == self) && (self.x_path.include?(move.destination) == false))
				boardstate.movelist.delete(move)
			end
		end
	end
end

class King < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("king", team, tilename, serial, game, depth)
		team = nil
		if color == "black"
			team = game.black_team
		else
			team = game.white_team
		end
		if team.kings.count < (depth.abs + 1)
			team.kings.push(self)
		else
			team.kings[depth.abs] = self
		end
	end
	def simulate #the simulate method for kings has to be able to update the king of the appropriate simlevel
		king_simulation = King.new(self.color, self.tile.coordinates.name, self.serial, self.game, (self.depth - 1)) #the tile given as an argument should be the one with the same depth
		return king_simulation
	end
	def criteria(boardstate)
		piece_moves = boardstate.movelist.select {|move| move.piece == self}
		piece_moves.each do |move|
			unless (((move.destination.coordinates.x_axis - move.departure.coordinates.x_axis).abs == (1 || 0)) && ((move.destination.coordinates.y_axis - move.departure.coordinates.y_axis).abs == (1 || 0)))
				piece_moves.delete(move)
			end
		end
		boardstate.movelist.each do |move|
			if ((move.piece == self) && (piece_moves.include?(move) == false))
				boardstate.movelist.delete(move)
			end
		end
	end
	def castle_destination(rook_departure) #where will this piece end up if it castles?
		if rook_departure.coordinates.name == "A1" #note: this will probably crash if it is unable to castle
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "C1"}
		elsif rook_departure.coordinates.name == "A8"
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "C8"}
		elsif rook_departure.coordinates.name == "H1"
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "G1"}
		elsif rook_departure.coordinates.name == "H8"
			return self.simlevel.tiles.find {|tile| tile.coordinates.name == "G1"}
		end
	end
end

class Queen < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("queen", team, tilename, serial, game, depth)
	end
	def simulate
		simpiece = Queen.new(self.color, self.tile.coordinates.name, self.serial, self.game, (self.depth - 1)) #the tile given as an argument should be the one with the same depth
		simpiece.moved = self.moved
		return simpiece
	end
	def criteria(boardstate)
		boardstate.movelist.each do |move|
			if ((move.piece == self) && (self.asterisk_path.include?(move.destination) == false))
				boardstate.movelist.delete(move)
			end
		end
	end
end

class Pawn < Piece
	attr_accessor :orientation
	def initialize(color, tilename, serial, game, depth = 0)
		super("pawn", color, tilename, serial, game, depth)
		@orientation = 1 #which way is this pawn moving?
		if color == "black"
			@orientation = (-1)
		end
	end
	def simulate
		simpiece = Pawn.new(self.color, self.tile.coordinates.name, self.serial, self.game, (self.depth - 1)) #the tile given as an argument should be the one with the same depth
		simpiece.moved = self.moved
		return simpiece
	end
	def one_tile_ahead
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == (self.coordinates.y_axis + (1*self.orientation)))) && (tile.coordinates.x_axis == self.coordinates.x_axis))}
	end
	def two_tiles_ahead
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == (self.coordinates.y_axis + (2*self.orientation)))) && (tile.coordinates.x_axis == self.coordinates.x_axis))}
	end
	def right_diagonal #the tile ahead and to the right that the pawn can move to iff it is occupied by an enemy piece
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == (self.coordinates.y_axis + (1*self.orientation)))) && (tile.coordinates.x_axis == (self.coordinates.x_axis + 1)))}
	end
	def left_diagonal
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == (self.coordinates.y_axis + (1*self.orientation)))) && (tile.coordinates.x_axis == (self.coordinates.x_axis - 1)))}
	end
	def right_adjacent
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == self.coordinates.y_axis)) && (tile.coordinates.x_axis == (self.coordinates.x_axis + 1)))}
	end
	def left_adjacent
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == self.coordinates.y_axis)) && (tile.coordinates.x_axis == (self.coordinates.x_axis - 1)))}
	end
	def right_passant #the tile two squares ahead and one square to the right that an enemy pawn would need to have moved from in order to give this piece the opportunity to make an en_passant move
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == (self.coordinates.y_axis + (2*self.orientation)))) && (tile.coordinates.x_axis == (self.coordinates.x_axis + 1)))}
	end
	def left_passant
		return self.simlevel.tiles.find {|tile| (((tile.coordinates.y_axis == (self.coordinates.y_axis + (2*self.orientation)))) && (tile.coordinates.x_axis == (self.coordinates.x_axis - 1)))}
	end
	def criteria(boardstate) #reminder: do we need movelist?
		destinations = []
		if self.one_tile_ahead.occupied_piece == nil
			destinations.push(self.one_tile_ahead)
		elsif ((self.one_tile_ahead.occupied_piece == nil) && (self.two_tiles_ahead.occupied_piece == nil) && (self.moved == false))
			destinations.push(self.one_tile_ahead)
			destinations.push(self.two_tiles_ahead)
		end
		if ((self.right_diagonal != nil) && (self.right_diagonal.occupied_piece != nil) && (self.right_diagonal.occupied_piece.team == self.team.opposite))
			destinations.push(self.right_diagonal)
		end
		if ((self.left_diagonal != nil) && (self.left_diagonal.occupied_piece != nil) && (self.left_diagonal.occupied_piece.team == self.team.opposite))
			destinations.push(self.left_diagonal)
		end
		boardstate.movelist.each do |move|
			if ((move.piece == self) && (destinations.include?(move.destination) == false ))
				boardstate.movelist.delete(move)
			end
		end #the next set of if statements deals with en_passant
		if ((self.game.history.last != nil) && (self.game.history.last.piece.rank == "pawn") && (self.game.history.last.first_move == true) && (self.game.history.last.destination == left_adjacent) && (self.game.history.last.departure == self.left_passant))
			en_passant_move = Move.new(self.game, (self.simlevel.tiles.find {|tile| (tile.coordinates == self.coordinates)}), left_diagonal)
			en_passant_move.taken = self.left_adjacent.occupied_piece
			boardstate.movelist.push(en_passant_move)
		elsif ((self.game.history.last != nil) && (self.game.history.last.piece.rank == "pawn") && (self.game.history.last.first_move == true) && (self.game.history.last.destination == right_adjacent) && (self.game.history.last.departure == self.right_passant))
			en_passant_move = Move.new(self.game, (self.simlevel.tiles.find {|tile| (tile.coordinates == self.coordinates)}), diagonal)
			en_passant_move.taken = self.right_adjacent.occupied_piece
			boardstate.movelist.push(en_passant_move)
		end
	end
	def promotion_prompt
		valid_response = false
		until valid_response == true
			puts "What would you like to promote your pawn to?"
			promotion = gets.chomp.downcase
			# replacement = nil
			# commented out the above line because I can't remember what it's for
			if promotion == "queen"
				valid_response = true
			elsif promotion == "knight"
				valid_response = true
			elsif promotion == "bishop"
				valid_response = true
			elsif promotion == "rook"
				valid_response = true
			elsif promotion == "king"
				puts "Sorry, there can only be one king."
			elsif promotion == "pawn"
				puts "Sorry, you can't end your turn without promoting your pawn."
			else
				puts "Sorry, I didn't understand that."
			end
		end
		return promotion
	end
	def promote(promotion)
		if promotion == "random"
			possibilities = ["queen", "knight", "bishop", "rook"]
			promotion = possibilities[rand(1..4)]
		end
		if promotion == "queen"
			replacement = Queen.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		elsif promotion == "knight"
			replacement = Knight.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		elsif promotion == "bishop"
			replacement = Bishop.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		elsif promotion == "rook"
			replacement = Rook.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		end
		self.tile.occupied_piece = replacement
		replacement.moved = true
		self.coordinates = nil
	end
end

class Tile
	attr_accessor :color, :occupied_piece, :bread, :meat, :piece_symbol, :color_square, :coordinates, :depth
	def initialize(x, y, depth = 0)
		alphanum = num_to_alphanum(x, y)
		@coordinates = nil
		if $coordinates.find {|coordinate| coordinate.name == alphanum} == nil
			@coordinates = Coordinates.new(alphanum)
		else
			@coordinates = $coordinates.find {|coordinate| coordinate.name == alphanum}
		end
		@depth = depth
		@occupied_piece = nil
		@color = determinecolor(@coordinates.x_axis, @coordinates.y_axis) #tells us whether the tile is white or black
		if @color == "white"
			@color_square = $white_square #used to help color the tile appropriately when displayed
		elsif @color == "black"
			@color_square = $black_square
		end
		@piece_symbol = @color_square #tiles are empty when first created
		@bread = @color_square * 3 #this string will serve as both the upper and lower third of this tile when displayed on the board when we call the board_display function
		@meat = @color_square + @piece_symbol + @color_square #this string will serve as the middle third of this tile when displayed on the board
	end
	def determinecolor(x_axis, y_axis)
		# helps specify the color of a tile based on the x and y coordinates
		total = x_axis + y_axis
		# If the sum of the x and y coordinates is evem, then it should be black.
		# Otherwise it should be white.
		is_even = (total % 2).zero?
		if is_even == true
			return "white"
		else
			return "black"
		end
	end
	def simulate
		simtile = Tile.new((self.coordinates.x_axis), (self.coordinates.y_axis), (self.depth - 1))
		unless self.occupied_piece == nil
			simtile.occupied_piece = self.occupied_piece.simulate
		end
		return simtile
	end
	def center_update
		if self.occupied_piece == nil
			self.piece_symbol = self.color_square
		else
			self.piece_symbol = $piece_symbols[self.occupied_piece.title]
		end
		self.meat = self.color_square + self.piece_symbol + self.color_square
	end
end

class Team
	attr_accessor :color, :player, :king, :check, :kings, :game
	def initialize(color, player, game)
		@color = color
		@player = player
		@game = game
		@kings = [] #gives us an easy way of finding the king for any given simlevel
		@check = false #is this team's king currently in check?
	end
	def king
		return self.kings[0]
	end
	def sim_king
		return self.kings[0]
	end
	def metasim_king
		return self.kings[0]
	end
	def opposite
		if self.color == "white"
			return self.game.black_team
		elsif self.color == "black"
			return self.game.white_team
		end
	end
end

$players = []

class Player #will probably be used in save states later
	attr_accessor :color, :name
	def initialize(color, name)
		@color = color #this may change from game to game
		@name = name
		$players.push(self)
	end
end

class Move
	attr_accessor :departure, :piece, :destination, :taken, :team, :enemy, :turn, :extras, :game_end, :snapshot, :previous_turn, :following_turn, :game, :ally_check_cache, :enemy_check_cache, :first_move
	def initialize(game, departure, destination) #set taken to nil if no piece is taken
		@game = game
		@departure = departure #the tile the moving piece is leaving from
		@piece = departure.occupied_piece
		@destination = destination #the tile the moving piece is arriving at
		@taken = nil
		unless @destination == "castle"
			@taken = destination.occupied_piece
		end
		@moving_team = @piece.team #the team that is making the move
		@enemy = @piece.team.opposite
		@turn = game.boardstate.turn_counter
		@game_end = nil #reminder: use this in game_over, anything other than nil indicates it is a game over, the string refers to how
		@snapshot = nil #at the END of the move
		@previous_turn = nil
		@following_turn = nil
		@ally_check_cache = nil #these will be used to cache the results of check_detect as needed
		@enemy_check_cache = nil
		@first_move = @piece.moved
	end
	def white_check
		if self.moving_team == self.game.white_team
			return self.ally_check
		else
			return self.enemy_check
		end
	end
	def black_check
		if self.moving_team == self.game.black_team
			return self.ally_check
		else
			return self.enemy_check
		end
	end
	def ally_check #if friendly_check_detect has been not performed before, run it; else return the cached value
		if self.ally_check_cache == nil
			return self.ally_check_detect
		else
			return self.ally_check_cache
		end
	end
	def enemy_check
		if self.enemy_check_cache == nil
			return self.enemy_check_detect
		else
			return self.enemy_check_cache
		end
	end
	def ally_check_detect
		outcome = self.simulate_outcome
		generate_valid_moves(outcome) #the problem is here
		possible_moves = outcome.movelist
		if ((possible_moves.empty? == false) && (possible_moves.find {|move| ((move.taken != nil) && (move.taken.rank == "king"))} != nil))
			self.ally_check_cache = true
		else
			self.ally_check_cache = false
		end
		return self.ally_check_cache
	end
	def enemy_check_detect
		outcome = self.simulate_outcome
		outcome.moving_team = outcome.moving_team.opposite #we proceed as though the moving team gets another free turn
		unless ((self.piece.rank == "pawn") && ((self.destination.coordinates.y_axis == 8) || (self.destination.coordinates.y_axis == 1)))
			generate_valid_moves(outcome)
			possible_moves = outcome.movelist
			if possible_moves.find {|move| move.taken.rank == "king"} != nil
				self.enemy_check_cache = true
			else
				self.enemy_check_cache = false
			end
		else
			self.enemy_check_cache = false
			pawn = outcome.pieces.find {|piece| piece.name == self.piece.name}
			pawn.promote("queen") #there are no situations where promoting to a rook or bishop would result in check but promoting to a queen wouldn't.
			generate_valid_moves(outcome)
			possible_moves = outcome.movelist
			if possible_moves.find {|move| move.taken.rank == "king"} != nil
				self.enemy_check_cache = true
			end
			outcome = self.simulate_outcome
			outcome.moving_team = outcome.moving_team.opposite
			pawn = outcome.pieces.find {|piece| piece.name == self.piece.name}
			pawn.promote("knight")
			generate_valid_moves(outcome)
			possible_moves = outcome.movelist
			if possible_moves.find {|move| move.taken.rank == "king"} != nil
				self.enemy_check_cache = true
			end
		end
		return enemy_check_cache
	end
	def simulate_outcome
		simstate = (self.game.simlevels.find {|level| (level.depth == self.piece.depth)}).simulate
		if self.destination == "castle"
			rook_departure = simstate.tiles.find {|tile| tile.coordinates == self.departure.coordinates}
			rook_destination = self.piece.castle_destination
			rook = simstate.pieces.find {|piece| piece.name == self.piece.name}
			king = simstate.friendly_king
			king_destination = king.castle_destination(rook_departure)
			king_departure = king.tile
			king_destination.occupied_piece = king
			king_departure.occupied_piece = nil
			rook_destination.occupied_piece = rook
			rook.moved = true
			rook_departure.occupied_piece = nil
			king.coordinates = king_destination.coordinates
			king.moved = true
			rook.coordinates = rook_destination.coordinates
			simstate.moving_team = simstate.moving_team.opposite
		else
			destination = simstate.tiles.find {|tile| tile.coordinates == self.destination.coordinates}
			departure = simstate.tiles.find {|tile| tile.coordinates == self.departure.coordinates}
			moved_piece = simstate.pieces.find {|piece| piece.name == self.piece.name}
			moved_piece.coordinates = nil
			destination.occupied_piece = moved_piece
			departure.occupied_piece = nil
			moved_piece.coordinates = destination.coordinates
			simstate.moving_team = simstate.moving_team.opposite
		end
		return simstate
	end
end

def execute_move(move)
	move.previous_turn = move.game.history.last
	move.previous_turn.following_turn = move
	puts "#{move.team.color.capitalize} moves their #{move.piece.rank} from #{move.departure.cordinates.name} to #{move.destination.coordinates.name}."
	unless move.taken == nil
		move.taken.tile.occupied_piece = nil
		move.taken.coordinates = nil
		puts "#{move.team.color.capitalize}'s #{move.piece.rank} has taken #{move.enemy.color}'s' #{move.taken.rank}"
	end
	unless (move.taken != nil) || (move.piece.rank == pawn)
		move.game.boardstate.fifty_move_counter += 1
	end
	move.piece.coordinates = destination.coordinates
	move.destination.occupied_piece = move.piece
	move.departure.occupied_piece = nil
	if ((move.piece.rank == "pawn") && ((move.destination.coordinates.y_axis == 8) || (move.destination.coordinates.y_axis == 1)))
		if move.moving_team.player.name == "AI"
			piece.promote("random")
		else
			piece.promote(piece.promotion_prompt)
		end
	end
	move.game.move_history.push(move) #reminder: should this happen before or after game over?
	move.game.boardstate.turn_counter += 1
	move.piece.moved = true
	move.game.boardstate.moving_team = move.team.opposite
	move.snapshot = Snapshot.new(move.game.boardstate)
	generate_valid_moves(move.game.boardstate)
	if (move.enemy_check == true) && (move.game.boardstate.movelist.find {|found_move| found_move.ally_check == false} == nil) #aka checkmate
		game_over(move, checkmate)
	elsif (move.enemy_check == false) && (move.game.boardstate.movelist.find {|found_move| found_move.ally_check == false} == nil)
		game_over(move, stalemate)
	end
	if move.game.boardstate.fifty_move_counter == 50
		game_over(move, "fifty moves")
	end
	board_display(move.game.board)
	if (move.enemy_check == true)
		puts "#{move.enemy.capitalize}'s king is in check!"
	end
	if move.game.boardstate.fifty_move_counter == 20
		puts "It has been 20 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 30 turns, the game will end\nin a draw."
	elsif move.game.boardstate.fifty_move_counter == 30
		puts "It has been 30 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 20 turns, the game will end\nin a draw."
	elsif move.game.boardstate.fifty_move_counter == 40
		puts "It has been 40 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 10 turns, the game will end\nin a draw."
	elsif move.game.boardstate.fifty_move_counter == 45
		puts "It has been 45 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 5 turns, the game will end\nin a draw."
	end
	identical_moves = move.game.history.select {|past_move| (past_move.snapshot == move.snapshot)}
	if identical_moves.count == 2
		puts "The board has already been in this state before. If this happens\nagain, the game will result in a draw."
	elsif identical_moves.count == 3
		puts "The board has been in this state three times. The game ends in a draw."
		game_over("three moves")
	end
end

def board_create #generates all 64 tiles of the board
	board = []
	for x in (1..8) # makes an array for each row of tiles
		board.push([])
	end
	board.each do |row| #adds 8 tiles with the appropriate coordinates to each row
		for x in (1..8)
			tile = Tile.new(x, (board.index(row) + 1), 0)
			row.push(tile)
		end
	end
	return board
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

def test_protocol #debugging tool
	board_create
	piece_change(($tiles.find { |tile| tile.coordinates.name == "H1"}), ("white rook")) #why is this not changing the piece symbol?
	puts $tiles.find {|tile| tile.coordinates.name == "H1"}.color_square
	puts $tiles.find {|tile| tile.coordinates.name == "H1"}.occupied_piece.name #to be used as a template later
	puts $tiles.find {|tile| tile.coordinates.name == "H1"}.color
	puts $tiles.find {|tile| tile.coordinates.name == "H1"}.coordinates.name
	board_display
end

def starting_pieces(game) #returns an array of all pieces in their starting postions
	pieces = [
	Rook.new("white", "A1", 1, game, 0),
	Knight.new("white", "B1", 1, game, 0),
	Bishop.new("white", "C1", 1, game, 0),
	Queen.new("white", "D1", 1, game, 0),
	King.new("white", "E1", 1, game, 0),
	Bishop.new("white", "F1", 2, game, 0),
	Knight.new("white", "G1", 2, game, 0),
	Rook.new("white", "H1", 2, game, 0),
	Pawn.new("white", "A2", 1, game, 0),
	Pawn.new("white", "B2", 2, game, 0),
	Pawn.new("white", "C2", 3, game, 0),
	Pawn.new("white", "D2", 4, game, 0),
	Pawn.new("white", "E2", 5, game, 0),
	Pawn.new("white", "F2", 6, game, 0),
	Pawn.new("white", "G2", 7, game, 0),
	Pawn.new("white", "H2", 8, game, 0),
	Rook.new("black", "A8", 1, game, 0),
	Knight.new("black", "B8", 1, game, 0),
	Bishop.new("black", "C8", 1, game, 0),
	Queen.new("black", "D8", 1, game, 0),
	King.new("black", "E8", 1, game, 0),
	Bishop.new("black", "F8", 2, game, 0),
	Knight.new("black", "G8", 2, game, 0),
	Rook.new("black", "H8", 2, game, 0),
	Pawn.new("black", "A7", 1, game, 0),
	Pawn.new("black", "B7", 2, game, 0),
	Pawn.new("black", "C7", 3, game, 0),
	Pawn.new("black", "D7", 4, game, 0),
	Pawn.new("black", "E7", 5, game, 0),
	Pawn.new("black", "F7", 6, game, 0),
	Pawn.new("black", "G7", 7, game, 0),
	Pawn.new("black", "H7", 8, game, 0) ]
	return pieces
end

def board_fill(board, pieces)
	board.flatten.each do |tile|
		tile.occupied_piece = pieces.find {|piece| piece.coordinates == tile.coordinates}
	end
end

def generate_valid_moves(boardstate) #returns a list of every possible valid move for a given turn from an array of tiles
	departures = boardstate.tiles.dup #this will be a list of every tile which contains a piece that can be moved
	boardstate.movelist = [] #this is a list of all valid moves for the given state of the board, will be returned at the end
	departures.each do |departure|
		if departure.occupied_piece == nil || #removes all moves starting on unoccupied tiles from the list
				departure.occupied_piece.team != boardstate.moving_team #ensures that the player is only allowed to move their own pieces
			departures.delete(departure)
		else #now that we have a list of tiles containing friendly pieces, we can generate possible moves for each piece
			valid_destinations = boardstate.tiles.dup #this will be a list of valid destinations for a given departure
			valid_destinations.each do |destination|
				if ((destination.occupied_piece != nil) && (destination.occupied_piece.team == boardstate.moving_team)) #removes tiles occupied by friendly pieces from the list of valid destinations
					valid_destinations.delete(destination)
				else
					move = Move.new(boardstate.game, departure, destination) #if all criteria are met, the move is added to the list of valid moves
					boardstate.movelist.push(move)
				end
			end
		end
	end
	boardstate.pieces.each do |piece|
		nonself_moves_before = boardstate.movelist.select {|move| move.piece != piece}
		# we need to have a record so that we know if a piece's criteria is
		# messing with moves that don't belong to that piece
		if piece.team == boardstate.moving_team
			piece.criteria(boardstate)
		end
		nonself_moves_after = boardstate.movelist.select {|move| move.piece != piece}
		unless nonself_moves_before == nonself_moves_after
			raise "#{piece.name} is adding or deleting other pieces' moves"
			# each piece's criteria should be deleting any invalid moves that move
			# that piece, and, in the case of a rook, adding an option to castle if
			# applicable. If moves that move other pieces get added or removed,
			# something isn't working correctly.
		end
	end
	puts "done" #delete later
	# for debugging: going to try only changing boardstate.movelist instead of
	# => also returning it
	#return boardstate.movelist #note: we do not determine at this stage whether these moves will put the friendly king in check, because that would be absolute hell in terms of both memory efficieny and our ability to read the code.
end

def start_new_game #unfinished, need to add protocols for ending the game (updating scoreboard etc)
	white_player_name = nil
	black_player_name = nil
	loop do
		puts %Q(What is the white player's name?\n(To assign an AI to white team, enter the name "AI")) #future improvement: add the ability to save and load players
		white_player_name = gets.chomp
		#reminder: I think the code commented out directly below is identical to the
		# => code after this loop but before the  end of start_new_game where
		# => white_player is defined
		#white_player = $players.find {|player| player.name == white_player_name}
		#if white_player == nil
		#	white_player = Player.new("white", white_player_name)
		#end
		puts %Q(What is the black player's name?\n(To assign an AI to black team, enter the name "AI"))
		black_player_name = gets.chomp
		break if ((black_player_name != white_player_name) || (black_player_name == "AI")) #reminder: fix everything related to AI vs AI games
		puts "Sorry, both teams cannot have the same player."
	end
	black_player = $players.find {|player| player.name == black_player_name}
	if black_player == nil
		black_player = Player.new("black", black_player_name)
	end
	white_player = $players.find {|player| player.name == white_player_name}
	if white_player == nil
		white_player = Player.new("white", white_player_name)
	end
	Game.new(white_player, black_player).play
end

def turn_prompt(boardstate)
	if boardstate.movelist.find {|move| move.ally_check == false} == nil
		if boardstate.game.history.last.enemy_check == true
			game_over(game, "checkmate")
		elsif boardstate.game.history.last.enemy_check == false
			game_over(game, "stalemate")
		end
	end
	if boardstate.moving_team.player.name == "AI"
		movelist = boardstate.movelist.select {|move| move.ally_check == false}
		move = movelist[rand(movelist.count) - 1]
		execute_move(move)
	else
		loop do
			board_display(boardstate.game.board)
			movelist = boardstate.movelist.dup
			puts "It is #{moving_team.player.name}'s turn."
			puts "What is the coordinate of the piece I should move?"
			puts %Q(Please reply in the form of a coordinate, e.g. "B2".)
			puts %Q(You can also enter "surrender" to surrender, "draw" to agree to a draw,\n"move history" to view move history, or "exit" to exit\nthe game with or without saving.)
			movelist.each do |move| #delete later
				if move.destination == "castle"
					puts move.piece.name + " " + move.departure.coordinates.name + " castle"
				else
					puts move.piece.name + " " + move.departure.coordinates.name + " to " + move.destination.coordinates.name
				end
			end
			response = gets.chomp.upcase
			if (response.length == 2)
				if tiles.any? {|tile| tile.coordinates.name == response} == false
					board_display(boardstate.game.board)
					puts "Sorry, that's not a valid coordinate."
				else
					departure = tiles.find {|tile| tile.coordinates.name == response}
					movelist = movelist.select {|found_move| found_move.departure.coordinates.name == response} #the list of possible moves will now only contain moves from the specified tile
					if movelist.empty? == true #displays error messages if the specified coordinate has no valid moves
						if departure.occupied_piece == nil
							board_display(boardstate.game.board)
							puts "Sorry, that tile is unoccupied."
						elsif departure.occupied_piece.team != moving_team
							board_display(boardstate.game.board)
							puts "Sorry, the piece belongs to the other player."
						else
							board_display(boardstate.game.board)
							puts "Sorry, that piece has no valid moves."
						end
					else
						puts "Where would you like to move it to?"
						can_castle = false
						if movelist.find {|found_move| ((found_move.departure == departure) && (found_move.destination == "castle"))}
							puts %Q(You can also say "castle" to castle.)
							can_castle = true
						end
						response = gets.chomp.upcase
						if ((!response.casecmp("castle")) && (can_castle == true))
							departure.occupied_piece.castle
						elsif tiles.any? {|tile| tile.coordinates.name == response} == false
							board_display(boardstate.game.board)
							puts "Sorry, that's not a valid coordinate."
						else
							destination = boardstate.tiles.find {|tile| tile.coordinates.name == response}
							move = movelist.find {|found_move| found_move.destination.coordinates.name == response}
							if (move == nil) && ((destination.occupied_piece == nil) || (destination.occupied_piece.team != moving_team))
								board_display(boardstate.game.board)
								puts "Sorry, that's not a valid move for that piece."
							elsif ((move.destination.occupied_piece =! nil) && (move.destination.occupied_piece.team == moving_team))
								puts "Sorry, that tile is already occupied by a friendly piece."
								board_display(boardstate.game.board)
							elsif move.ally_check == true
								board_display(boardstate.game.board)
								puts "Sorry, that move would put your king in check."
							else
								execute_move(move)
							end
						end
					end
				end
			elsif response == "move history"
				move_history_prompt #unfinished: add this
				board_display(boardstate.game.board)
			elsif response == "surrender" #unfinished: need to add a "game over" method
				game_over(nil, "surrender") #reminder: make sure that the game_over method can handle surrenders with nil moves (the surrender is credited to the previous move)
			elsif response == "draw"
				loop do
					puts "Do both players agree to a draw?" #future improvement: maybe have some mechanism to ask both players?
					response = gets.chomp.downcase
					if response == "yes"
						game_over(nil, "draw")
						break
					elsif response == "no"
						break
					else
						puts "Sorry, I didn't understand that."
					end
				end
			elsif response == "exit"
				boardstate.game.exit_game
			else
				puts "Sorry, I didn't understand that."
			end
		end
	end
end

def display_scoreboard #future improvement: add name feature, add the ability to save and load scoreboards, probably change this entirely to deal with a large number of player names
	valid_response = false
	until valid_response == true #keeps asking until it gets a valid input
		puts "\nWhich scoreboard would you like to view?"
		puts %Q(You can say "human vs human", "human vs AI", "both", or "back".\n)
		response = gets.chomp.downcase
		if response == "human vs human"
			puts "\nPlayer 1 has #{$pvp_scoreboard[0]} point(s)."
			puts "Player 2 has #{$pvp_scoreboard[1]} point(s)."
			valid_response = true
		elsif response == "human vs AI"
			puts "\nHuman has #{$AI_scoreboard[0]} point(s)."
			puts "Chessbot has #{$AI_scoreboard[1]} point(s)."
			valid_response = true
		elsif response == "both"
			puts "\nPlayer 1 has #{$pvp_scoreboard[0]} point(s)."
			puts "Player 2 has #{$pvp_scoreboard[1]} point(s).\n"
			puts "Human has #{$AI_scoreboard[0]} point(s)."
			puts "Chessbot has #{$AI_scoreboard[1]} point(s)."
			valid_response = true
		else
			puts "\nSorry, I didn't understand that."
		end
	end
end

=begin
To explain how the display works: each tile is a 3x3 arrangement of unicode characters, like so:

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

def board_display(board) #each tile is represented by a 3x3 grid of characters, with the icon of the occupying piece in the center
	board.flatten.each do |tile|
		tile.center_update
	end
	board.reverse.each do |row| #I know this is sloppy and I should go back and put the board in the right order in the first place, but whatever
		rowbread = "  " #this string will serve as the upper and lower thirds of the row
		rowmeat = (board.index(row) + 1).to_s + " " #the middle third of the row, with the y-axis coordinate to the left
		row.each do |tile|
			rowbread = rowbread + tile.bread #adds the top three characters of the tile
			rowmeat = rowmeat + tile.meat
		end
		print rowbread
		if board.index(row) <= 3 #this will display the legend to the right of the board.
			puts "   " + $legend_numbered[board.index(row)][0][0] + "=" + $legend_numbered[board.index(row)][0][1]
		else
			puts "" #there are only twelve piece symbols, so only the first twelve lines are needed for the legend
		end
		print rowmeat
		if board.index(row) <= 3
			puts "   " + $legend_numbered[board.index(row)][1][0] + "=" + $legend_numbered[board.index(row)][1][1]
		else
			puts ""
		end
		print rowbread
		if board.index(row) <= 3
			puts "   " + $legend_numbered[board.index(row)][2][0] + "=" + $legend_numbered[board.index(row)][2][1]
		else
			puts ""
		end
	end
	puts " | A  B  C  D  E  F  G  H |" #the letters corresponding to the x-coordinates of the tiles, displayed below the board
end

def main_menu #asks the user for prompts when the program is first opened or after a game is completed
	$close_chess = false
	until $close_chess == true #future improvement: options to save and load games/scoreboards
		valid_response = false
		until valid_response == true
			puts %Q(\nWhat would you like to do? You can say "new game",\n"view scoreboard" "change display colors", or "close"\n ) #reminder: add the ability to load games
			response = gets.chomp.downcase
			if response == "new game"
				start_new_game
				valid_response = true
			elsif response == "view scoreboard"
				display_scoreboard
				valid_response = true
			elsif response == "change display colors"
				negquery
			elsif response == "close"
				$close_chess = true #reminder: how should this work?
				valid_response = true
			else
				puts "Sorry, I didn't understand that."
			end
		end
	end
end

$first_negquery = true

def initiate
	negquery
	main_menu
end

#and now on to the actual running of the program

if $needs_testing == true #this step is ony for debugging
	$test_protocol
end

def move_class_count(movelist) #for debugging
	class_count = []
	movelist.each do |move|
		move_class = class_count.find {|foo| foo[0] == move.class.to_s}
		if move_class == nil
			class_count.push([move.class.to_s, 1])
		else
			move_class[1] += 1
		end
	end
	puts "begin class list"
	class_count.each do |moveclass|
		puts moveclass[0] + " " + moveclass[1].to_s
	end
	puts "end class list"
end

initiate
