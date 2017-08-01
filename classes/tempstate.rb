class TempState
	@@last_sim_id = nil
	attr_accessor :game, :tiles, :board, :pieces, :depth, :turn_counter,
	:moving_team, :fifty_move_counter, :game_over, :movelist
	include Simulations
	def initialize(game, pieces, previous_temp = nil)
		# previous_temp is another TempState object which allows us to generate a
		# new TempState object in the context of a simulation or execution of a move
		@pieces = pieces
		# note: pieces will normally be previous_temp.pieces
		@game = game
		# same with game. It's easier to do it this way since we will sometimes
		# want to provide nil values for this, such as when calling neg_display
		raise if @pieces && @pieces.uniq! {|piece| [piece.coordinates, piece.depth]}
		# I.E. if there are two pieces occupying the same tile
		if previous_temp
			@board = previous_temp.board
			@depth = previous_temp.depth
			@turn_counter = previous_temp.turn_counter
			@fifty_move_counter = previous_temp.fifty_move_counter
			@game_over = previous_temp.depth
		else
			@board = board_create(game)
			@depth = 0
			@turn_counter = 0
			@fifty_move_counter = 0
			@game_over = false
		end
		@tiles = @board.flatten
		@movelist = []
		self.set_sim_id
		@pieces.each {|piece| piece.sim_id = self.sim_id} if @pieces
		@tiles.each {|tile| tile.sim_id = self.sim_id}
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
end
