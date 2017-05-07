# the word "bug" in comments will be used to flag unfixed bugs
$needs_testing = false #used for debugging

$neg_display = true # controls whether or not to invert the black and white colors in the display

$pvp_scoreboard = [0, 0]
$AI_scoreboard = [0, 0]

$players = []

class Coordinates
	attr_accessor :x_axis, :y_axis, :letter, :name
	def initialize(text)
		@letter = text.chop.upcase #isolates the letter in the coordinates
		@y_axis = text.reverse.chop.to_i #isolates the y-coordinate
		@x_axis = self.class.letter_to_x(@letter) #changes the letter to a row number
		@name = text
		$coordinates.push(self)
	end
	ALPH = ["taken", "A", "B", "C", "D", "E", "F", "G", "H"]# used to translate between letter and row number
	def self.x_to_letter(x_coordinate) #converts x coordinates to letters
		ALPH[x_coordinate]
	end
	def self.letter_to_x(letter) #converts letters to x coordinates
		ALPH.index(letter)
	end
	def self.alphanum_to_num(text) #for converting e.g. "A1" to "(1, 1)"
		letter = text.chop.downcase #isolates the letter in the coordinates
		y_axis = text.reverse.chop.to_i #isolates the y-coordinate
		x_axis = self.letter_to_x(letter) #translates the letter to an x-coordinate
		[x_axis, y_axis]
	end
	def self.num_to_alphanum(x_axis, y_axis) #for converting e.g. "(1, 1)" to "A1"
		letter = self.x_to_letter(x_axis) #translates the x-coordinate to a letters
		letter + y_axis.to_s #combines the letter and y-coordinate to create a single name
	end
end

$coordinates = []

class Game
	attr_accessor :simlevels, :white_player, :black_player, :white_team,
	:black_team, :name, :history, :pieces, :board, :tiles, :boardstate
	def initialize(white_player, black_player)
		@white_player = white_player
		@black_player = black_player
		@black_team = Team.new("black", @black_player, self)
		@white_team = Team.new("white", @white_player, self)
		@pieces = self.create_starting_pieces
		@board = board_create(self) #the "board" attribute is a two-dimensional array of all tiles that is only used in the board_display function
		@tiles = @board.flatten
		@simlevels = []
		@boardstate = Boardstate.new(self, @board, @pieces, 0)
		@boardstate.moving_team = @white_team
		@simlevels.push(self.boardstate)
		@simlevels.push(Simlevel.new(self, [[]], 0))
		@simlevels.push(Simlevel.new(self, [[]], -1))
		@name = nil #to be used when saving and loading games
		@history = []
		#gonna try moving the line commented out below to game.play
		#@boardstate.movelist = generate_valid_moves(@boardstate)
	end
	def moving_team
		self.simlevels.first.moving_team
	end
	def play
		self.boardstate.generate_valid_moves
		$playing = true #reminder: make sure this updates when ending or saving a game
		until $playing == false
			TurnMenu.new(self)
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
	def create_starting_pieces #returns an array of all pieces in their starting postions
		pieces = [
		Rook.new("white", "A1", 1, self, 0),
		Knight.new("white", "B1", 1, self, 0),
		Bishop.new("white", "C1", 1, self, 0),
		Queen.new("white", "D1", 1, self, 0),
		King.new("white", "E1", 1, self, 0),
		Bishop.new("white", "F1", 2, self, 0),
		Knight.new("white", "G1", 2, self, 0),
		Rook.new("white", "H1", 2, self, 0),
		Pawn.new("white", "A2", 1, self, 0),
		Pawn.new("white", "B2", 2, self, 0),
		Pawn.new("white", "C2", 3, self, 0),
		Pawn.new("white", "D2", 4, self, 0),
		Pawn.new("white", "E2", 5, self, 0),
		Pawn.new("white", "F2", 6, self, 0),
		Pawn.new("white", "G2", 7, self, 0),
		Pawn.new("white", "H2", 8, self, 0),
		Rook.new("black", "A8", 1, self, 0),
		Knight.new("black", "B8", 1, self, 0),
		Bishop.new("black", "C8", 1, self, 0),
		Queen.new("black", "D8", 1, self, 0),
		King.new("black", "E8", 1, self, 0),
		Bishop.new("black", "F8", 2, self, 0),
		Knight.new("black", "G8", 2, self, 0),
		Rook.new("black", "H8", 2, self, 0),
		Pawn.new("black", "A7", 1, self, 0),
		Pawn.new("black", "B7", 2, self, 0),
		Pawn.new("black", "C7", 3, self, 0),
		Pawn.new("black", "D7", 4, self, 0),
		Pawn.new("black", "E7", 5, self, 0),
		Pawn.new("black", "F7", 6, self, 0),
		Pawn.new("black", "G7", 7, self, 0),
		Pawn.new("black", "H7", 8, self, 0) ]
	end
end

class Snapshot
	attr_accessor :team_to_move, :move, :fossils, :turn_counter
	def initialize(boardstate)
		@team_to_move = boardstate.moving_team
		@move = boardstate.game.history.last
		@turn_counter = boardstate.turn_counter
		@fossils = Hash.new #records of the pieces and their positions on the board
		@special_move_opportunities = []
		boardstate.tiles.each do |tile| #I chose to do this with the tiles array rather than the pieces array because the order of the former never changes, and we want to be able to check whether the hashes are identical
			@fossils[tile.occupied_piece.title] = tile.occupied_piece.coordinates if tile.occupied_piece
			if ((tile.occupied_piece.is_a?(Rook) && tile.occupied_piece.can_castle?) ||
				((tile.occupied_piece.is_a?(Pawn)) &&
				(boardstate.game.history.last.destination == tile) &&
				((boardstate.game.history.last.departure.coordinates.y_axis - tile.coordinates.y_axis).abs == 2)))
				@special_move_opportunities.push(tile)
			end
		end
	end
end

class Boardstate #redundant, but makes things easier to read
	attr_accessor :game, :tiles, :board, :board, :pieces, :depth, :turn_counter,
	:moving_team, :fifty_move_counter, :game_over, :movelist
	def initialize(game, board, pieces, depth = 0)
		@game = game
		@board = board
		@tiles = board.flatten #remember, these are to reflect only the attributes of the game at the time of creation
		@pieces = pieces
		@depth = depth
		@turn_counter = 0
		@fifty_move_counter = 0
		@game_over = false #reminder: do we need this? If so, should it be moved to game instead?
		@movelist = [] #list of all possible valid moves for the next turn
	end
	def white_king
		self.pieces.find {|piece| piece.title == "white king"}
	end
	def black_king
		self.pieces.find {|piece| piece.title == "black king"}
	end
	def active_pieces # pieces that have not been taken
		pieces.select {|piece| piece.coordinates} # taken pieces have nil coordinates
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
		else
			return self.white_king
		end
	end
	def go_deeper
		sublevel = game.simlevels.find {|level| level.depth == (@depth - 1)}
		return sublevel
	end
	def simulate
		deeper = Simlevel.new(self.game, self.board, self.depth)
		if self.game.simlevels.count < self.depth.abs + 2 && self.game.simlevels.count >= 3
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
	def legend
		rows = []
		if self.pieces
			self.pieces.each do |piece|
				rows.push ("   #{piece.title}=#{piece.symbol}" )
			end
			rows.uniq!.sort!
		end
		rows
	end
	def display #each tile is represented by a 3x3 grid of characters, with the icon of the occupying piece in the center
		legend = self.legend
		self.board.reverse.each do |row| # I know this is sloppy and I should go back and put the board in the right order in the first place, but whatever
			self.print_row(self.board, row, legend)
		end
		puts " | A  B  C  D  E  F  G  H |" #the letters corresponding to the x-coordinates of the tiles, displayed below the board
	end
	def print_row(board, row, legend)
		rowbread = "  " #this string will serve as the upper and lower thirds of the row
		rowmeat = (board.index(row) + 1).to_s + " "
		row.each do |tile|
			rowbread += tile.bread #adds the top/bottom three characters of the tile
			rowmeat += tile.meat #adds the middle three characters of the tile
		end
		puts rowbread + legend.slice!(1).to_s
		puts rowmeat + legend.slice!(1).to_s
		puts rowbread + legend.slice!(1).to_s
	end
	def generate_valid_moves #returns a list of every possible valid move for a given turn from an array of tiles
		self.movelist = [] #this is a list of all valid moves for the given state of the board, will be returned at the end
		mover_pieces = self.active_pieces.select {|piece|
			piece.team == self.moving_team
		}
		mover_pieces.each do |piece|
			nonself_moves_before = self.movelist.select {|move| move.piece != piece}
			# we need to have a record so that we know if a piece's criteria is
			# messing with moves that don't belong to that piece
			destinations = piece.criteria
			destinations.each do |destination|
				if destination.occupied_piece && destination.occupied_piece.team == piece.team
					next
				else
					move = Move.new(self.game, piece.tile, destination)
					self.movelist.push(move)
				end
			end
			nonself_moves_after = self.movelist.select {|move| move.piece != piece}
			unless nonself_moves_before == nonself_moves_after
				puts "piece.tile = #{piece.tile.name}, #{piece.depth.to_s} piece.name = #{piece.name} #{piece.simlevel.object_id}"
				puts "added:"
				(nonself_moves_after - nonself_moves_before).each do |move|
					puts "#{move.piece.name} #{move.piece.depth.to_s} #{move.departure.name} #{move.destination.name}  #{move.simlevel.object_id}"
				end
				puts "removed:"
				(nonself_moves_before- nonself_moves_after).each do |move|
					puts "#{move.piece.name} #{move.departure.name} #{move.destination.name}, #{move.simlevel.object_id}"
				end
				raise "#{piece.name} is adding or deleting other pieces' moves"
				# each piece's criteria should be deleting any invalid moves that move
				# that piece, and, in the case of a rook, adding an option to castle if
				# applicable. If moves that move other pieces get added or removed,
				# something isn't working correctly.
			end
		end
		self.movelist.each do |move|
			if move.destination == "castle"
				#this is only here to avoid calling "castle".destination and getting an error
			#	puts "#{move.piece.name} castle" #delete later
			elsif ((move.destination.occupied_piece != nil) && (move.destination.occupied_piece.team == move.piece.team)) ||
					self.tiles.include?(move.destination) == false ||
					move.destination == move.departure
				self.movelist.delete(move)
			else
			#	puts "#{move.piece.name} #{move.departure.coordinates.name} to #{move.destination.coordinates.name}" #delete later
			end
		end
		# for debugging: going to try only changing boardstate.movelist instead of
		# => also returning it
		#return boardstate.movelist #note: we do not determine at this stage whether these moves will put the friendly king in check, because that would be absolute hell in terms of both memory efficieny and our ability to read the code.
		self.movelist
	end
end


class Simlevel < Boardstate #used for check_detect and checkmate_detect
	def initialize(game, superboard = [], superdepth) #the "super" prefix means that something is from the level above the one being created
		@game = game
		@depth = (superdepth - 1) #how many levels of simulation deep are we?
		@board = []
		@pieces = []
		superboard.each do |superrow|
			row = []
			superrow.each do |supertile|
				simtile = supertile.simulate
				row.push(simtile)
				unless simtile.occupied_piece == nil
					@pieces.push(simtile.occupied_piece)
				end
			end
			@board.push(row)
		end
		@tiles = board.flatten
		@moving_team = self.wake_up.moving_team
		@white_king = @pieces.find {|piece| piece.title == "white king"}
		@black_king = @pieces.find {|piece| piece.title == "black king"}
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
		@rook_dest = @rook_tiles.last if @rook_tiles
		@king_dest = @king_tiles.last if @king_tiles
	end
	def find_rook_path
		rook_path_hash = {
			"A1" => ["B1", "C1" "D1"], "A8" => ["B8", "C8" "D8"],
			"H1" => ["G1", "F1"], "H8" => ["G8", "F8"]
		}
		tiles = self.rook.simlevel.tiles
		rook_path_hash[self.rook.tile.coordinates.name.capitalize].each do |coor|
			tile = tiles.find {|tile| tile.coordinates.name == coor}
			self.rook_tiles.push(tile) if tile
		end
	end
	def find_king_path
		king_path_hash = {
			"A1" => ["E1", "D1" "C1"], "A8" => ["E8", "D8" "C8"],
			"H1" => ["E1", "F1", "G1"], "H8" => ["E8", "F8", "G1"]
		}
		king_path_hash[self.rook.tile.name.capitalize].each do |coor|
			tile = tiles.find {|tile| tile.coordinates.name == coor}
			self.king_tiles.push(tile)
		end
	end
	def clear?
		if self.rook_tiles.is_a?(Array) && !self.rook_tiles.empty?
			!(self.rook_tiles.any? {|tile| tile.occupied_piece})
		end
	end
	def safe?
		self.king_tiles.any? {|tile|
			Move.new(self.rook.game, king.tile, tile).ally_check == true
		}
	end
end

class Piece
	attr_accessor :coordinates, :serial, :depth, :game, :moved, :color
	class << self; attr_accessor :black_symbol, :white_symbol end
	@white_symbol = "?"
	@black_symbol = "?"
	def initialize(color, tilename, serial, game, depth = 0)
		@depth = depth
		@color = color
		@game = game
		@coordinates = $coordinates.find {|coor| coor.name == tilename.upcase}
		self.clear_tile if @game && @game.simlevels && self.tile
		@serial = serial
		@moved = false
	end
	def clear_tile
		current_occupants = self.simlevel.pieces.select {|piece|
			piece.coordinates == self.coordinates
		}
		current_occupants.each do |piece|
			piece.coordinates = nil
		end
	end
	def title
		color + " " + self.class.to_s.downcase
	end
	def name
		color + "_" + self.class.to_s + "_" + serial.to_s
	end
	def symbol_color
		symb_color = self.color
		if $neg_display && symb_color == "black"
			symb_color == "white"
		elsif $neg_display && symb_color == "white"
			symb_color == "black"
		end
		symb_color
	end
	def symbol(color = self.symbol_color)
		if color == "white"
			raise if self.class.white_symbol.nil?
			return self.class.white_symbol
		else
			raise if self.class.black_symbol.nil?
			return self.class.black_symbol
		end
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
		piece_sim.simlevel.pieces.push(piece_sim)
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
	def move_to(dest) # can accept a string, tile, or coordinates
		if dest.is_a?(String)
			dest = simlevel.tiles.find {|tile| tile.coordinates.name == dest}
		elsif dest.is_a?(Coordinates)
			dest = simlevel.tiles.find {|tile| tile.coordinates == dest}
		end
		raise "Not a valid destination" unless dest.is_a?(Tile)
		dest.occupied_piece.coordinates = nil if dest.occupied_piece
		self.coordinates = dest.coordinates
		self.moved = true
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
	@white_symbol = "♜"
	@black_symbol = "♖"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
	end
	def can_castle?
		king = self.team.kings[self.depth.abs]
		both_unmoved = (self.moved == false && king.moved == false) # have the king or rook or both been moved yet?
		return false unless both_unmoved
		self.castle_path = CastlePath.new(self)
		self.castle_tiles = @castle_path.rook_tiles
		self.castle_dest = @castle_tiles.last
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
		move.piece.move_to(destination.coordinates)
		king = move.simlevel.king
		king_destination = self.castle_path.king_dest
		king_departure = king.tile # reminder: do we need this?
		king.move_to(king_destination.coordinates)
		move.game.history.push(move) #reminder: should this happen before or after game over?
		move.simlevel.turn_counter += 1
		move.piece.moved = true
		move.simlevel.moving_team = move.team.opposite
		move.snapshot = Snapshot.new(move.simlevel)
		move.simlevel.generate_valid_moves
		if (move.enemy_check == true) && (move.simevel.movelist.find {|found_move| found_move.ally_check == false} == nil) #aka checkmate
			game_over(move, checkmate)
		elsif (move.enemy_check == false) && (move.simlevel.movelist.find {|found_move| found_move.ally_check == false} == nil)
			game_over(move, stalemate)
		end
		# move.game.boardstate.display
		if (move.enemy_check == true)
			puts "#{move.enemy.capitalize}'s king is in check!"
		end
	end
end

class Knight < Piece
	@white_symbol = "♞"
	@black_symbol = "♘"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
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
	@white_symbol = "♝"
	@black_symbol = "♗"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
	end
	def criteria
		self.x_path
	end
end

class King < Piece
	@white_symbol = "♚"
	@black_symbol = "♔"
	def initialize(color, tilename, serial, game, depth = 0)
		super(color, tilename, serial, game, depth)
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
	@white_symbol = "♛"
	@black_symbol = "♕"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
	end
	def criteria
		(self.plus_path + self.x_path)
	end
end

class Pawn < Piece
	@white_symbol = "♟"
	@black_symbol = "♙"
	attr_accessor :orientation
	def initialize(color, tilename, serial, game, depth = 0)
		super(color, tilename, serial, game, depth)
		@orientation = 1 #which way is this pawn moving?
		if color == "black"
			@orientation = (-1)
		end
	end
	def one_tile_ahead(destinations)
		dest = self.simlevel.tiles.find {|tile|
			tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
			tile.coordinates.x_axis == self.coordinates.x_axis
		}
		unless !dest || dest.occupied_piece
			destinations.push(dest)
			return dest
		end
	end
	def two_tiles_ahead(destinations)
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + 2*self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis
		}
		destinations.push(dest) unless !dest || dest.occupied_piece || self.moved
	end
	def right_diagonal(destinations) #the tile ahead and to the right that the
		# pawn can move to if it's occupied by an enemy piece
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis + 1
		}
		taken = dest.occupied_piece if dest
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
		if (!!taken && taken.team != self.team && taken.is_a?(Pawn) &&
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
		if (!!taken && taken.team != self.team && taken.is_a?(Pawn) &&
			!!last_move && last_move.piece == taken &&
			last_move.departure == passant &&
			last_move.destination == self.left_adjacent)
			return l_diag
		else
			return nil
		end
	end
	def add_passant_moves(r_pass, l_pass)
		if r_pass
			en_passant_move = Move.new(self.game, self.tile, r_pass)
			en_passant_move.taken = self.right_adjacent.occupied_piece
			self.simlevel.movelist.push(en_passant_move)
		elsif l_pass # there can only be one en passant move, because the
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
	def promotion_conditions(move)
		if [1, 8].include?(move.destination.coordinates.y_axis) &&
			move.team.player.name == "AI"
			self.promote("random", move)
		elsif [1, 8].include?(move.destination.coordinates.y_axis)
			self.promotion_prompt(move)
		end
	end
	def promotion_prompt(move)
		loop do
			puts "What would you like to promote your pawn to?"
			response = gets.chomp.capitalize
			break unless self.promote(response, move)
			self.promotion_error_message(response)
		end
	end
	PROMO_KLASSES = [Queen, Knight, Bishop, Rook]
	def promote(response, move)
		promo_klass = PROMO_KLASSES.find {|klass| klass.to_s == response.capitalize}
		promo_klass = PROMO_KLASSES.sample if response == "Random"
		return nil unless promo_klass
		klassmates = self.simlevel.pieces.select {|piece|
			piece.is_a?(promo_klass) && piece.team == self.team
		}
		serial = klassmates.count + 1
		replacement = promo_klass.new(self.team, self.move.departure.name, serial, self.game, self.depth)
		self.coordinates = nil
		replacement.moved = true
		replacement
	end
	def promotion_error_message(response)
		if response == "king"
			puts "Sorry, there can only be one king."
		elsif response == "pawn"
			puts "Sorry, you can't promote to a pawn."
		else
			puts "Sorry, I didn't understand that."
		end
	end
end

class Tile
	attr_accessor :coordinates, :depth, :game
	def initialize(x, y, depth = 0, game = nil)
		alphanum = Coordinates.num_to_alphanum(x, y)
		@coordinates =  $coordinates.find {|coordinate| coordinate.name == alphanum}
		@coordinates = Coordinates.new(alphanum) unless @coordinates
		@depth = depth
		@game = game
	end
	def boardstate
		self.game.simlevels.find {|level| level.depth == self.depth}
	end
	def occupied_piece
		if self.game
			self.boardstate.pieces.find {|piece| piece.coordinates == self.coordinates}
		else
			return nil
		end
	end
	def name
		self.coordinates.name
	end
	def color
		# helps specify the color of a tile based on the x and y coordinates
		total = self.coordinates.x_axis + self.coordinates.y_axis
		# If the sum of the x and y coordinates is evem, then it should be black.
		# Otherwise it should be white.
		is_even = (total % 2).zero?
		if is_even == true
			return "white"
		else
			return "black"
		end
	end
	def color_square
		if ((self.color == "black") && $neg_display) || ((self.color == "white") && !$neg_display)
			return "■" #used to help color the tile appropriately when displayed
		else
			return "□"
		end
	end
	def simulate
		simtile = Tile.new((self.coordinates.x_axis), (self.coordinates.y_axis), (self.depth - 1), self.game)
		self.occupied_piece.simulate if self.occupied_piece
		simtile
	end
	def center_symbol
		if self.occupied_piece
			return self.occupied_piece.symbol
		else
			return self.color_square
		end
	end
	def meat
		if self.color_square.nil? || self.center_symbol.nil?
			puts "piece = #{self.occupied_piece.name} color_square = #{self.color_square.to_s} center_symbol = #{self.center_symbol.to_s}"
		end
		#this string will serve as both the upper and lower third of this tile when
		#displayed on the board when we call the board_display function
		(self.color_square + self.center_symbol + self.color_square)
	end
	def bread
		(self.color_square * 3)
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
		else
			raise "invalid team color"
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
	def initialize(game, departure, destination)
		@game = game
		@departure = departure #the tile the moving piece is leaving from
		@piece = departure.occupied_piece
		@team = @piece.team
		@simlevel = @game.simlevels.find {|level| level.depth == @piece.depth}
		@destination = destination #the tile the moving piece is arriving at
		@taken = nil # set taken to nil if no piece is taken
		unless @destination == "castle"
			@taken = destination.occupied_piece # reminder: do we need to set taken to nil?
		end
		@enemy = @piece.team.opposite
		@turn = game.boardstate.turn_counter
		@first_move = @piece.moved
		# reminder: use @game_end in game_over, anything other than nil indicates it is a game over, the string refers to how/why
		# @ snapshot is taken at the END of the move
		# @check_cache will be used to cache the results of check_detect as needed
	end
	def white_check
		if self.team == self.game.white_team
			return self.ally_check
		else
			return self.enemy_check
		end
	end
	def black_check
		if self.team == self.game.black_team
			return self.ally_check
		else
			return self.enemy_check
		end
	end
	def ally_check #if friendly_check_detect has been not performed before, run it; else return the cached value
		if self.ally_check_cache.nil?
			return self.ally_check_detect
		else
			return self.ally_check_cache
		end
	end
	def enemy_check
		if self.piece.is_a?(Pawn) && self.enemy_check_cache.nil? &&
			[1, 8].include?(self.destination.coordinates.y_axis)
			return self.promotion_check_detect(outcome)
		elsif self.enemy_check_cache.nil?
			return self.enemy_check_detect
		else
			return self.enemy_check_cache
		end
	end
	def ally_check_detect
		outcome = self.simulate_outcome
		outcome.generate_valid_moves
		possible_moves = outcome.movelist
		if possible_moves.any? {|move| move.taken.is_a?(King)}
			self.ally_check_cache = true
		else
			self.ally_check_cache = false
		end
		self.ally_check_cache
	end
	def enemy_check_detect(outcome = self.simulate_outcome)
		outcome.moving_team = outcome.moving_team.opposite #we proceed as though the moving team gets another free turn
		possible_moves = outcome.generate_valid_moves
		if possible_moves.any? {|move| move.taken.is_a?(King)}
			return self.enemy_check_cache = true
		else
			return self.enemy_check_cache = false
		end
	end
	def promotion_check_detect
		["queen", "knight"].each do |klass| # there are no situations where promoting to a rook or bishop would result in check but promoting to a queen wouldn't.
			promotion_outcome = self.simulate_outcome
			to_be_promoted = promotion_outcome.pieces.find {|piece|
				piece.name == self.piece.name
			}
			to_be_promoted.promote(klass)
			self.enemy_check_detect(promotion_outcome)
			break if self.enemy_check_cache == true
		end
		self.enemy_check_cache
	end
	def simulate_outcome
		simstate = (self.game.simlevels.find {|level| (level.depth == self.piece.depth)}).simulate
		if self.destination == "castle"
			self.simulate_castle(simstate)
		else
			self.simulate_move(simstate)
		end
		simstate
	end
	def simulate_castle(simstate)
		rook = simstate.pieces.find {|piece| piece.name == self.piece.name}
		rook_destination = self.piece.castle_dest
		raise unless rook.is_a?(Rook)
		king = simstate.friendly_king
		king_destination = rook.castle_path.king_dest
		raise unless king.is_a?(King)
		king.move_to(king_destination.coordinates)
		rook.move_to(rook_destination.coordinates)
		simstate.moving_team = simstate.moving_team.opposite
	end
	def simulate_move(simstate)
		moved_piece = simstate.pieces.find {|piece| piece.name == self.piece.name}
		moved_piece.move_to(self.destination.coordinates)
		simstate.moving_team = simstate.moving_team.opposite
	end
	def execute
		self.previous_turn = self.game.history.last
		self.previous_turn.following_turn = self if self.previous_turn
		puts "#{self.team.color.upcase} moves their #{self.piece.class.to_s} from #{self.departure.coordinates.name} to #{self.destination.coordinates.name}."
		puts "#{self.team.color.capitalize}'s #{self.piece.class.to_s} has taken #{self.enemy.color}'s' #{self.taken.class.to_s}" if self.taken
		self.piece.move_to(self.destination)
		if (self.piece.is_a?(Pawn) && [1, 8].include?(self.destination.coordinates.y_axis))
			self.piece.promotion_conditions(self)
		end
		self.game.history.push(self) #reminder: should this happen before or after game over?
		self.simlevel.turn_counter += 1
		self.piece.moved = true
		self.simlevel.moving_team = self.simlevel.moving_team.opposite
		self.snapshot = Snapshot.new(self.simlevel)
		self.mate_detect
		self.game.boardstate.display
		self.three_move_rule
		self.fifty_move_rule
		if self.enemy_check
			puts "#{self.enemy.player.name.upcase}'s king is in check!"
		end
	end
	def mate_detect
		self.simlevel.generate_valid_moves
		valid_move = self.simlevel.movelist.find {|found_move| !found_move.ally_check}
		if self.enemy_check && !valid_move # aka checkmate
			game_over(self, "checkmate") #reminder: the game_over method will pobably be made part of the game class
		elsif !valid_move # aka stalemate
			game_over(self, "stalemate")
		end
	end
	def three_move_rule
		identical_moves = self.game.history.select {|past_move| (past_move.snapshot == self.snapshot)}
		if identical_moves.count == 2
			puts "The board has already been in this state before. If this happens\nagain, the game will result in a draw."
		elsif identical_moves.count == 3
			puts "The board has been in this state three times. The game ends in a draw."
			game_over("three moves") # reminder: the game_over method will pobably be made part of the game class
		end
	end
	def fifty_move_rule
		# reminder: this should allow either player to declare a draw rather than force one on both of them
		fmc = self.simlevel.fifty_move_counter
		fmc += 1 unless self.taken || self.piece.is_a?(Pawn)
		if fmc == 50
			game_over(self, "fifty moves")
		elsif fmc > 19 && (fmc % 10 == 0) || (50 - fmc < 10)
			puts "It has been #{fmc.to_s} moves since a pawn has been"
			puts "moved or a piece has been taken."
			puts "If no piece is captured or pawn moved in the next"
			puts "#{(50 - fmc).to_s} turns, the game will end in a draw."
		end
	end
end

def board_create(game = nil) #generates all 64 tiles of the board
	board = []
	for x in (1..8) # makes an array for each row of tiles
		board.push([])
	end
	board.each do |row| #adds 8 tiles with the appropriate coordinates to each row
		for x in (1..8)
			tile = Tile.new(x, (board.index(row) + 1), 0, game)
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

def test_protocol(movelist) #debugging tool
	movelist.each do |move| #delete later
		if move.destination == "castle"
			puts move.piece.name + " " + move.departure.coordinates.name + " castle"
		else
			puts move.piece.name + " " + move.departure.coordinates.name + " to " + move.destination.coordinates.name
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

if $needs_testing == true # this step is ony for debugging
	$test_protocol
end

class TurnMenu
	attr_accessor :game, :boardstate
	def initialize(game)
		@game = game
		@boardstate = game.boardstate
		self.ai_or_human
	end
	def ai_or_human
		moving_player_name = self.boardstate.moving_team.player.name
		if moving_player_name.upcase == "AI"
			self.ai_move
		else
			self.human_prompt
		end
	end
	def ai_move
		movelist = self.boardstate.movelist.select {|move| move.ally_check == false}
		movelist.sample.execute
	end
	def human_prompt
		loop do
			self.boardstate.display
			movelist = self.boardstate.movelist.dup
			puts "It is #{self.boardstate.moving_team.player.name}'s turn."
			puts "What is the coordinate of the piece I should move?"
			puts %Q(Please reply in the form of a coordinate, e.g. "B2".)
			puts %Q(You can also enter "surrender" to surrender, "draw" to agree to a draw,\n"move history" to view move history, or "exit" to exit\nthe game with or without saving.)
			#test_protocol(movelist) #delete later
			response = gets.chomp.upcase
			if (response.length == 2)
				self.human_move(response, movelist)
				break
			elsif response == "move history"
				self.move_history_prompt #unfinished: add this
				self.boardstate.display
			elsif response == "surrender" #unfinished: need to add a "game over" method
				self.game_over(nil, "surrender") #reminder: make sure that the game_over method can handle surrenders with nil moves (the surrender is credited to the previous move)
			elsif response == "draw"
				self.draw_prompt
				break # reminder: this just causes human)_turn_prompt to be called again
			elsif response == "exit"
				self.boardstate.game.exit_game #reminder: make this
			else
				puts "Sorry, I didn't understand that."
			end
		end
	end
	def human_move(response, movelist)
		departure = self.boardstate.tiles.find {|tile|
			tile.coordinates.name == response
		}
		if departure
			movelist.select! {|found_move| found_move.departure.coordinates.name == response} #the list of possible moves will now only contain moves from the specified tile
			self.destination_prompt(departure, movelist)
		else
			self.boardstate.display
			puts "Sorry, that's not a valid coordinate."
		end
	end
	def destination_prompt(departure, movelist)
		if movelist.empty?#displays error messages if the specified coordinate has no valid moves
			self.empty_movelist_message(departure)
		else
			puts "Where would you like to move it to?"
			can_castle = false
			if movelist.find {|found_move| ((found_move.departure == departure) && (found_move.destination == "castle"))}
				puts %Q(You can also say "castle" to castle.)
				can_castle = true
			end
			response = gets.chomp.upcase
			if (!response.casecmp("castle") && can_castle)
				departure.occupied_piece.castle
			elsif !self.boardstate.tiles.any? {|tile| tile.coordinates.name == response}
				self.boardstate.display
				puts "Sorry, that's not a valid coordinate."
			else
				self.normal_move(departure, movelist, response)
			end
		end
	end
	def normal_move(departure, movelist, response)
		destination = self.boardstate.tiles.find {|tile| tile.coordinates.name == response}
		move = movelist.find {|found_move| found_move.destination.coordinates.name == response}
		if move.nil? && (!destination.occupied_piece || (destination.occupied_piece.team != boardstate.moving_team))
			self.boardstate.display
			puts "Sorry, that's not a valid move for that piece."
		elsif move.nil? && (destination.occupied_piece && destination.occupied_piece.team == boardstate.moving_team)
			puts "Sorry, that tile is already occupied by a friendly piece."
			self.boardstate.display
		elsif move.ally_check == true
			self.boardstate.display
			puts "Sorry, that move would put your king in check."
		else
			move.execute
		end
	end
	def empty_movelist_message(departure)
		self.boardstate.display
		if departure.occupied_piece.nil?
			puts "Sorry, that tile is unoccupied."
		elsif departure.occupied_piece.team != self.boardstate.moving_team
			puts "Sorry, the piece belongs to the other player."
		else
			puts "Sorry, that piece has no valid moves."
		end
	end
	def draw_prompt
		loop do
			puts "Do both players agree to a draw?" #future improvement: maybe have some mechanism to ask both players?
			response = gets.chomp.downcase
			if response == "yes"
				self.game_over(nil, "draw")
				break
			elsif response == "no"
				break
			else
				puts "Sorry, I didn't understand that."
			end
		end
	end
end

class MainMenu
	attr_accessor :game, :first_negquery
	def initialize
		@first_negquery = true
		self.negquery
		self.main_menu_prompt
	end
	def negquery
		Boardstate.new(nil, board_create, nil).display
		negdone = false
		if self.first_negquery == true
			puts "Hi, welcome to chess! Before we begin I need your help to set the display.\n"
		end
		loop do #keeps going until the user is satisfied with the appearance of the display
			puts "In the above board, does tile A1 appear black to you?\n"
			response = gets.chomp
			if response.downcase == "yes"
				if self.first_negquery == true
					puts "\nGood. Let's get started then."
					self.first_negquery = false
				end
				break
			elsif response.downcase == "no"
				$neg_display = !$neg_display
				board = board_create(nil)
				Boardstate.new(nil, board_create, nil).display
				"How about now?"
			else
				puts "Sorry, I didn't understand that."
			end
		end
	end
	def main_menu_prompt #asks the user for prompts when the program is first opened or after a game is completed
		loop do #future improvement: options to save and load games/scoreboards
			puts %Q(\nWhat would you like to do? You can say "new game",\n"view scoreboard" "change display colors", or "close"\n ) #reminder: add the ability to load games
			response = gets.chomp.downcase
			break if self.main_menu_execute(response) == "close_chess"
		end
	end
	def main_menu_execute(response)
		if response == "new game"
			self.start_new_game
		elsif response == "view scoreboard"
			self.display_scoreboard
		elsif response == "change display colors"
			self.negquery
		elsif response == "close"
			self.close_chess #reminder: how should this work?
			return "close_chess"
		else
			puts "Sorry, I didn't understand that."
		end
	end
	def display_scoreboard #future improvement: add name feature, add the ability to save and load scoreboards, probably change this entirely to deal with a large number of player names
		loop do #keeps asking until it gets a valid input
			puts "\nWhich scoreboard would you like to view?"
			puts %Q(You can say "human vs human", "human vs AI", "both", or "back".\n)
			response = gets.chomp.downcase
			if response == "human vs human"
				puts "\nPlayer 1 has #{$pvp_scoreboard[0]} point(s)."
				puts "Player 2 has #{$pvp_scoreboard[1]} point(s)."
				break
			elsif response == "human vs AI"
				puts "\nHuman has #{$AI_scoreboard[0]} point(s)."
				puts "Chessbot has #{$AI_scoreboard[1]} point(s)."
				break
			elsif response == "both"
				puts "\nPlayer 1 has #{$pvp_scoreboard[0]} point(s)."
				puts "Player 2 has #{$pvp_scoreboard[1]} point(s).\n"
				puts "Human has #{$AI_scoreboard[0]} point(s)."
				puts "Chessbot has #{$AI_scoreboard[1]} point(s)."
				break
			else
				puts "\nSorry, I didn't understand that."
			end
		end
	end
	def player_name_prompt
		loop do
			puts %Q(What is the white player's name?\n(To assign an AI to white team, enter the name "AI"))
			white_player_name = gets.chomp.upcase
			puts %Q(What is the black player's name?\n(To assign an AI to black team, enter the name "AI"))
			black_player_name = gets.chomp.upcase
			if (black_player_name != white_player_name) || black_player_name == "AI"
				return {"white" => white_player_name, "black" => black_player_name}
			end
			puts "Sorry, both teams cannot have the same player."
		end
	end
	def start_new_game #unfinished, need to add protocols for ending the game (updating scoreboard etc)
		# reminder: fix everything related to AI vs AI games
		# future improvement: add the ability to save and load players
		# reminder: make sure this can distinguish new players from old ones
		player_names = self.player_name_prompt
		white_player_name = player_names["white"]
		black_player_name = player_names["black"]
		black_player = $players.find {|player| player.name == black_player_name}
		black_player = Player.new("black", black_player_name) if black_player.nil?
		white_player = $players.find {|player| player.name == white_player_name}
		white_player = Player.new("white", white_player_name) if white_player.nil?
		self.game = Game.new(white_player, black_player)
		self.game.play
	end
end

MainMenu.new
