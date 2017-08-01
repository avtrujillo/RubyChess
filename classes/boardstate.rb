class Boardstate #redundant, but makes things easier to read
	@@last_sim_id = nil
	attr_accessor :game, :tiles, :board, :pieces, :depth, :turn_counter,
	:moving_team, :fifty_move_counter, :game_over, :movelist
	include Simulations
	def initialize(game, pieces, depth = 0)
		@game = game
		@board = self.board_create(@game)
		@tiles = board.flatten #remember, these are to reflect only the attributes of the game at the time of creation
		@pieces = pieces
		raise if @pieces && @pieces.uniq! {|piece| piece.coordinates}
		@depth = depth
		@turn_counter = 0
		@fifty_move_counter = 0
		@game_over = false #reminder: do we need this? If so, should it be moved to game instead?
		@movelist = [] #list of all possible valid moves for the next turn
		self.set_sim_id
		@pieces.each {|piece| piece.sim_id = self.sim_id} if @pieces
		@tiles.each {|tile| tile.sim_id = self.sim_id}
	end
	def self.create_move_outcome(move, boardstate_before = move.boardstate_before)
		Boardstate.new(move.game, boardstate_before, boardstate_before.depth)
		#unfinished
	end
	def set_sim_id
		simtime = Time.now.to_s
		if @@last_sim_id && @@last_sim_id[:last_simtime] == simtime
			@@last_sim_id[:sim_counter] = @@last_sim_id[:sim_counter] + 1
		else
			@@last_sim_id = {last_simtime: simtime.to_s, sim_counter: 1}
		end
		@sim_id = @@last_sim_id[:last_simtime] + @depth.to_s + @@last_sim_id[:sim_counter].to_s
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
	def find_tile(dest)
		if dest.is_a?(String)
			return self.tiles.find {|tile| tile.coordinates.name == dest}
		elsif dest.is_a?(Coordinates)
			return self.tiles.find {|tile| tile.coordinates == dest}
		else
			raise "must be a string or coordinates (#{dest.class.to_s})"
		end
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
		deeper.sim_parent = self
		self.sim_child = deeper
		if self.game.simlevels.count < self.depth.abs + 2 && self.game.simlevels.count >= 3
			self.game.simlevels.push(deeper)
		elsif self.game.simlevels.count >= (self.depth.abs + 2)
			self.game.simlevels[self.depth.abs + 1] = deeper
		end
		deeper
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
			rows.uniq!
			rows.sort!
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
	DEST_EMPTY_OR_ENEMY = Proc.new do |move|
		next true if move.destination == "castle"
		next false unless $coordinates.include?(move.destination.coordinates)
		next true if move.destination.occupied_piece.nil?
		next false if move.destination.occupied_piece.team == move.piece.team
		next false if move.destination == move.departure
		true
	end
	def generate_valid_moves #returns a list of every possible valid move for a given turn from an array of tiles
		self.movelist = [] #this is a list of all valid moves for the given state of the board, will be returned at the end
		mover_pieces = self.active_pieces.select do |piece|
			piece.team == self.moving_team && piece.tile
		end
		raise if mover_pieces.empty?
		mover_pieces.each {|piece| piece_valid_moves(piece)}
		self.movelist.select!(&DEST_EMPTY_OR_ENEMY)
		raise unless movelist.is_a?(Array)
		self.movelist
		#note: we do not determine at this stage whether these moves will put the friendly king in check, because that would be absolute hell in terms of both memory efficieny and our ability to read the code.
	end
	def piece_valid_moves(piece)
		nonself_moves_before = self.movelist.select {|move| move.piece.name != piece.name}
		destinations = piece.criteria
		destinations.each do |destination|
			raise unless piece.coordinates && piece.tile.coordinates
			piece.simlevel.pieces.push(piece) unless piece.simlevel.pieces.any? {|pc| (pc.name == piece.name) || (pc.coordinates == piece.coordinates && pc.coordinates)}
			if destination.occupied_piece.nil? || destination.occupied_piece.team != piece.team
			#	byebug unless piece.tile.boardstate.pieces.any? {|pc| pc == piece}
				raise unless piece.tile.game
				raise unless piece.depth == piece.tile.depth
				raise "#{piece.tile.coordinates.name} + #{piece.coordinates.name}" unless piece.tile.occupied_piece(piece)
				move = Move.new(self.game, piece.tile, destination)
				self.movelist.push(move)
			end
		end
		nonself_moves_after = self.movelist.select {|move| move.piece.name != piece.name}
		nonself_moves_edit_err_message(nonself_moves_before, nonself_moves_after, piece)
	end
	def nonself_moves_edit_err_message(nonself_moves_before, nonself_moves_after, piece)
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
end
