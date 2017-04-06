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
			if (((tile.occupied_piece.rank == "rook") && (tile.occupied_piece.can_castle? == true)) || ((tile.occupied_piece.rank == "pawn") && (boardstate.game.history.last.destination == tile) && ((boardstate.game.history.last.departure.y_axis - tile.y_axis).abs == 2)))
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

class Path # used to find the possible moves of a rook, bishop, or queen
	attr_accessor :x_step, :y_step, :piece, :name, :tiles, :x_ori, :y_ori
	def initialize(piece, name)
		@name = name
		@x_ori = self.set_x_orientation # in which direction, if any, do we move
		@y_ori = self.set_y_orientation # along the x or y axis during each step?
		@name = name
		@piece = piece
		@tiles = []
		@x_step = @piece.tile.coordinates.x_axis # what is the x- or y-coordinate
		@y_step = @piece.tile.coordinates.y_axis # of our current step?
		self.fill_path
	end
	def set_y_orientation
		if (self.name.upcase == "N") || (self.name.chop.upcase == "N")
			return 1
		elsif (self.name.upcase =="S") || (self.name.chop.upcase == "S")
			return -1
		else
			return 0
		end
	end
	def set_x_orientation
		if (self.name.upcase == "E") || (self.name.reverse.chop.upcase == "E")
			return 1
		elsif (self.name.upcase == "W") || (self.name.reverse.chop.upcase == "W")
			return -1
		else
			return 0
		end
	end
	def take_step # in order to find our path, we keep taking steps in a given
		self.x_step += self.x_ori # direction (up, down, left, right, diagonal)
		self.y_step += self.y_ori # until we run into another piece or reach the
		tiles = self.piece.simlevel.tiles
		step = tiles.find {|tile| tile.coordinates.x_axis == self.x_step &&
			tile.coordinates.y_axis == self.y_step
		}
	end
	def fill_path
		loop do
			step = self.take_step # end of the board
			if step == nil # if we have reached the end of the board
				break # we cannot take any more steps
			elsif step.occupied_piece == nil # if the tile is unoccupied it is added
				self.tiles.push(step) # to the path and we can take another step
			elsif step.occupied_piece.team == self.piece.team # if the tile is occupied
				break # by a friendly piece then we cannot take any more steps
			else # the only remaining possibility is that the tile is occupied by an
				self.tiles.push(step) # enemy piece, which means that we can make this
				break # step but cannot move beyond it
			end
		end
	end
end

class CastlePath # note: not a subclass of Path
	attr_accessor :rook, :tiles, :king_tiles, :king, :rook_tiles,
	:rook_dest, :king_dest
	def initialize(rook)
		@rook = rook
		@king = rook.team.kings[rook.depth.abs]
		@tiles = @rook.simlevel.tiles
		@rook_tiles = []
		@king_tiles = []
		self.find_rook_path
		self.find_rook_path
		@rook_dest = @path_tiles.last
		@king_dest = @king_tiles.last
	end
	def find_rook_path
		rook_path_hash = {
			"A1" => ["B1", "C1" "D1"], "A8" => ["B8", "C8" "D8"],
			"H1" => ["G1", "F1"], "H8" => ["G8", "F8"]
		}
		tiles = self.piece.simlevel.tiles
		rook_path_hash[self.piece.tile.name.capitalize].each do |coor|
			tile = tiles.find {|tile| tile.coordinates.name == coor}
			self.path_tiles.push(tile)
		end
	end
	def find_king_path
		king_path_hash = {
			"A1" => ["E1", "D1" "C1"], "A8" => ["E8", "D8" "C8"],
			"H1" => ["E1", "F1", "G1"], "H8" => ["E8", "F8", "G1"]
		}
		king_path_hash[self.piece.tile.name.capitalize].each do |coor|
			tile = tiles.find {|tile| tile.coordinates.name == coor}
			self.king_tiles.push(tile)
		end
	end
	def clear?
		!(self.rook_tiles.any? {|tile| !!tile.occupied_piece})
	end
	def safe?
		self.king_tiles.any? {|tile|
			Move.new(self.game, king.tile, tile).ally_check == true
		}
	end
end

class Piece
	attr_accessor :rank, :coordinates, :title, :name, :serial, :depth, :game, :moved, :color
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
		self.simlevel.tiles.find {
			|tile| tile.coordinates == self.coordinates
		}
	end
	def simulate
		piece_sim = self.class.new(self.color, self.tile.coordinates.name, self.serial, self.game, self.depth - 1)
		piece_sim.moved = self.moved
		piece_sim
	end
	def plus_path #all the possible moves of a rook
		north_path = Path.new(self, "N")
		east_path = Path.new(self, "E")
		south_path = Path.new(self, "S")
		west_path = Path.new(self, "W")
		north_path.tiles + east_path.tiles + south_path.tiles + west_path.tiles
	end
	def x_path # all the possible moves of a bishop
		nw_path = Path.new(self, "NW")
		ne_path = Path.new(self, "NE")
		se_path = Path.new(self, "SE")
		sw_path = Path.new(self, "SW")
		nw_path.tiles + ne_path.tiles + se_path.tiles + sw_path.tiles
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
	attr_accessor :castle_path, :castle_dest, :castle_tiles
	def initialize(team, tilename, serial, game, depth = 0)
		super("rook", team, tilename, serial, game, depth)
	end
	def can_castle?
		self.castle_path = CastlePath.new(self)
		self.castle_tiles = @castle_path.path_tiles
		self.castle_dest = @castle_tiles.last
		king = self.team.kings[self.depth.abs]
		both_unmoved = (self.moved == false && king.moved == false) # have the king or rook or both been moved yet?
		return false unless both_unmoved && !!self.castle_path
		clear = self.castle_path.clear?
		safe = self.castle_path.safe?
		last_move = game.history.last
		last_move_check = !(!last_move || !!last_move.enemy_check)
		(safe && !last_move_check)
	end
	def criteria
		if (self.depth > 2) && (self.serial < 3) && self.can_castle? #the former condition is in place to prevent infinite loops where check detect simulates castling as a possible move, which in turn must run check detect
			self.simlevel.movelist.push(Move.new(self.game, self.tile, "castle"))
		end
		self.plus_path
	end
	def castle(move)
		move.previous_turn = move.game.history.last
		move.previous_turn.following_turn = move
		puts "#{move.team.color.capitalize} castles from #{move.departure.cordinates.name}."
		move.piece.coordinates = destination.coordinates
		move.destination.occupied_piece = move.piece
		move.departure.occupied_piece = nil
		king = move.simlevel.king
		king_destination = self.castle_path.king_dest
		king_departure = king.tile
		king_destination.occupied_piece = king
		king_departure.occupied_piece = nil
		king.coordinates = king_destination.coordinates
		move.game.move_history.push(move) #reminder: should this happen before or after game over?
		move.simlevel.turn_counter += 1
		move.piece.moved = true
		move.simlevel.moving_team = move.team.opposite
		move.snapshot = Snapshot.new(move.simlevel)
		generate_valid_moves(move.simlevel)
		if (move.enemy_check == true) && (move.simevel.movelist.find {|found_move| found_move.ally_check == false} == nil) #aka checkmate
			game_over(move, checkmate)
		elsif (move.enemy_check == false) && (move.simlevel.movelist.find {|found_move| found_move.ally_check == false} == nil)
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
	def criteria
		valid_destinations = []
		possible_destinations = self.simlevel.tiles.dup
		possible_destinations.each do |dest|
			x_difference = (dest.coordinates.x_axis - self.tile.coordinates.x_axis).abs
			y_difference = (dest.coordinates.y_axis - self.tile.coordinates.y_axis).abs
			if (x_difference == 1 && y_difference == 2) || (x_difference == 2 && y_difference == 1)
				valid_destinations.push(dest)
			end
		end
		return valid_destinations
	end
end

class Bishop < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("bishop", team, tilename, serial, game, depth)
	end
	def criteria
		self.x_path
	end
end

class King < Piece
	def initialize(color, tilename, serial, game, depth = 0)
		super("king", color, tilename, serial, game, depth)
		if team.kings.count < (self.depth.abs + 1)
			team.kings.push(self)
		else
			team.kings[self.depth.abs] = self
		end
	end
	def criteria
		valid_destinations = []
		candidate_destinations = self.simlevel.tiles.dup
		candidate_destinations.each do |dest|
			x_diff = (dest.coordinates.x_axis - self.tile.coordinates.x_axis).abs
			y_diff = (dest.coordinates.y_axis - self.coordinates.y_axis).abs
			x_one_or_zero = ((x_diff == 1) || (x_diff == 0))
			y_one_or_zero = ((y_diff == 1) || (y_diff == 0))
			if x_one_or_zero && y_one_or_zero && dest != self.tile
				valid_destinations.push(dest)
			end
		end
		return valid_destinations
	end
end

class Queen < Piece
	def initialize(team, tilename, serial, game, depth = 0)
		super("queen", team, tilename, serial, game, depth)
	end
	def criteria
		(self.plus_path + self.x_path)
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
	def one_tile_ahead(destinations)
		dest = self.simlevel.tiles.find {|tile|
			tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
			tile.coordinates.x_axis == self.coordinates.x_axis
		}
		unless !dest || !!dest.occupied_piece
			destinations.push(dest)
			return true
		end
	end
	def two_tiles_ahead(destinations)
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + 2*self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis
		}
		destinations.push(dest) unless !dest || !!dest.occupied_piece || self.moved
	end
	def right_diagonal(destinations) #the tile ahead and to the right that the
		# pawn can move to if it's occupied by an enemy piece
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis + 1
		}
		taken = dest.occupied_piece if !!dest
		destinations.push(dest) unless !dest || !taken || taken.team == self.team
		dest
	end
	def left_diagonal(destinations)
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis - 1
		}
		taken = dest.occupied_piece if !!dest
		destinations.push(dest) unless !dest || !taken || taken.team == self.team
		dest
	end
	def right_adjacent
		self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis &&
		tile.coordinates.x_axis == self.coordinates.x_axis + 1
	}
	end
	def left_adjacent
		self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis &&
		tile.coordinates.x_axis == self.coordinates.x_axis - 1
	}
	end
	def right_passant(r_diag)
		#the tile two squares ahead and one square to the right that an enemy pawn would need to have moved from in order to give this piece the opportunity to make an en_passant move
		taken = self.right_adjacent.occupied_piece if !!self.right_adjacent
		last_move = self.game.history.last
		y_coor = self.coordinates.y_axis + 2*self.orientation
		x_coor = self.coordinates.x_axis + 1
		passant = self.simlevel.tiles.find { |tile|
			tile.coordinates.y_axis == y_coor && tile.coordinates.x_axis == x_coor }
		if (!!taken && taken.team != self.team && taken.class == Pawn &&
			!!last_move && last_move.piece == taken &&
			last_move.departure == passant &&
			last_move.destination == self.right_adjacent)
			return r_diag
		else
			return nil
		end
	end
	def left_passant(l_diag)
		taken = self.left_adjacent.occupied_piece if !!self.left_adjacent
		last_move = self.game.history.last
		y_coor = self.coordinates.y_axis + 2*self.orientation
		x_coor = self.coordinates.x_axis - 1
		passant = self.simlevel.tiles.find { |tile|
			tile.coordinates.y_axis == y_coor && tile.coordinates.x_axis == x_coor }
		if (!!taken && taken.team != self.team && taken.class == Pawn &&
			!!last_move && last_move.piece == taken &&
			last_move.departure == passant &&
			last_move.destination == self.left_adjacent)
			return l_diag
		else
			return nil
		end
	end
	def add_passant_moves(r_pass, l_pass)
		if !!r_pass
			en_passant_move = Move.new(self.game, self.tile, r_pass)
			en_passant_move.taken = self.right_adjacent.occupied_piece
			self.simlevel.movelist.push(en_passant_move)
		elsif !!l_pass # there can only be one en passant move, because the
			# destination of an en passant move is relative to the last move
			en_passant_move = Move.new(self.game, self.tile, l_pass)
			en_passant_move.taken = self.left_adjacent.occupied_piece
			self.simlevel.movelist.push(en_passant_move)
		end
	end
	def criteria
		destinations = []
		self.two_tiles_ahead(destinations) if self.one_tile_ahead(destinations)
		r_diag = self.right_diagonal(destinations)
		l_diag = self.left_diagonal(destinations)
		#the next set of if statements deals with en_passant
		r_pass = self.right_passant(r_diag)
		l_pass = self.left_passant(l_diag)
		self.add_passant_moves(r_pass, l_pass)
		return destinations
	end
	def promotion_prompt
		promotion = nil
		until valid_response == true
			puts "What would you like to promote your pawn to?"
			promotion = gets.chomp.downcase
			# replacement = nil
			# commented out the above line because I can't remember what it's for
			valid_responses = ["queen", "knight", "bishop", "rook"]
			if valid_responses.include?(promotion)
				break
			elsif promotion == "king"
				puts "Sorry, there can only be one king."
			elsif promotion == "pawn"
				puts "Sorry, you can't promote to a pawn."
			else
				puts "Sorry, I didn't understand that."
			end
		end
		return promotion
	end
	def create_replacement(promotion)
		if promotion == "queen"
			return Queen.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		elsif promotion == "knight"
			return Knight.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		elsif promotion == "bishop"
			return Bishop.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		elsif promotion == "rook"
			return Rook.new(self.team, self.tile.name, (((self.simlevel.pieces.select {|piece| piece.rank == promotion}).count) + 1), self.depth)
		end
	end
	def promote(promotion)
		if promotion == "random"
			promotion = ["queen", "knight", "bishop", "rook"].sample
		end
		replacement = self.create_replacement(promotion)
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
	attr_accessor :departure, :piece, :destination, :taken, :team, :enemy, :turn,
	:extras, :game_end, :snapshot, :previous_turn, :following_turn, :game,
	:ally_check_cache, :enemy_check_cache, :first_move, :simlevel
	def initialize(game, departure, destination) #set taken to nil if no piece is taken
		@game = game
		@departure = departure #the tile the moving piece is leaving from
		@piece = departure.occupied_piece
		@simlevel = @game.simlevels.find {|level| level.depth == @piece.depth}
		@destination = destination #the tile the moving piece is arriving at
		@taken = nil
		unless @destination == "castle"
			@taken = destination.occupied_piece
		end
		@moving_team = @piece.team #the team that is making the move
		@enemy = @piece.team.opposite
		@turn = game.boardstate.turn_counter
		@first_move = @piece.moved
		# reminder: use @game_end in game_over, anything other than nil indicates it is a game over, the string refers to how/why
		# @ snapshot is taken at the END of the move
		# @check_cache will be used to cache the results of check_detect as needed
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
			rook_destination = self.piece.castle_dest
			rook = simstate.pieces.find {|piece| piece.name == self.piece.name}
			king = simstate.friendly_king
			king_destination = rook.castle_path.king_dest
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
		move.simlevel.fifty_move_counter += 1
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
	move.simlevel.turn_counter += 1
	move.piece.moved = true
	move.simlevel.moving_team = move.team.opposite
	move.snapshot = Snapshot.new(move.simlevel)
	generate_valid_moves(move.simlevel)
	if (move.enemy_check == true) && (move.simlevel.movelist.find {|found_move| found_move.ally_check == false} == nil) #aka checkmate
		game_over(move, checkmate)
	elsif (move.enemy_check == false) && (move.simlevel.movelist.find {|found_move| found_move.ally_check == false} == nil)
		game_over(move, stalemate)
	end
	if move.simlevel.fifty_move_counter == 50
		game_over(move, "fifty moves")
	end
	board_display(move.game.board)
	if (move.enemy_check == true)
		puts "#{move.enemy.capitalize}'s king is in check!"
	end
	if move.simlevel.fifty_move_counter == 20
		puts "It has been 20 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 30 turns, the game will end\nin a draw."
	elsif move.simlevel.fifty_move_counter == 30
		puts "It has been 30 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 20 turns, the game will end\nin a draw."
	elsif move.simlevel.fifty_move_counter == 40
		puts "It has been 40 moves since a pawn has been moved or a pieces has been taken."
		puts "If no piece is captured or pawn moved in the next 10 turns, the game will end\nin a draw."
	elsif move.simlevel.fifty_move_counter == 45
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
end

def board_fill(board, pieces)
	board.flatten.each do |tile|
		tile.occupied_piece = pieces.find {|piece| piece.coordinates == tile.coordinates}
	end
end

def generate_valid_moves(boardstate) #returns a list of every possible valid move for a given turn from an array of tiles
	boardstate.movelist = [] #this is a list of all valid moves for the given state of the board, will be returned at the end
	mover_pieces = boardstate.pieces.select {|piece| piece.team == boardstate.moving_team}
	mover_pieces.each do |piece|
		nonself_moves_before = boardstate.movelist.select {|move| move.piece != piece}
		# we need to have a record so that we know if a piece's criteria is
		# messing with moves that don't belong to that piece
		destinations = piece.criteria
		destinations.each do |destination|
			if destination.occupied_piece && destination.occupied_piece.team == piece.team
				next
			else
				move = Move.new(boardstate.game, piece.tile, destination)
				boardstate.movelist.push(move)
			end
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
	boardstate.movelist.each do |move|
		if move.destination == "castle"
			#this is only here to avoid calling "castle".destination and getting an error
			puts "#{move.piece.name} castle" #delete later
		elsif ((move.destination.occupied_piece != nil) && (move.destination.occupied_piece.team == move.piece.team)) ||
				boardstate.tiles.include?(move.destination) == false ||
				move.destination == move.departure
			boardstate.movelist.delete(move)
		else
			puts "#{move.piece.name} #{move.departure.coordinates.name} to #{move.destination.coordinates.name}" #delete later
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
	available_move = boardstate.movelist.find {|move| move.ally_check == false}
	last_move = boardstate.game.history.last
	if !!available_move && !!last_move && boardstate.game.history.last.enemy_check
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
						if ((!response.casecmp("castle")) && (can_castle? == true))
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

# and now on to the actual running of the program

if $needs_testing == true # this step is ony for debugging
	$test_protocol
end

initiate
