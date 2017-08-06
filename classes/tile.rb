class Tile
	include Simulations
	attr_accessor :coordinates, :depth, :game
	def initialize(x, y, depth = 0, game = nil)
		alphanum = Coordinates.num_to_alphanum(x, y)
		@coordinates =  $coordinates.find {|coordinate| coordinate.name == alphanum}
		@coordinates = Coordinates.new(alphanum) unless @coordinates
		@depth = depth
		@game = game
	end
	def boardstate
		level = self.game.simlevels.find {|level| level.depth == self.depth}
		self.game.simlevels.find {|level| level.depth == self.depth}
	end
	def occupied_piece
		if self.game
			foo = (self.boardstate.pieces.uniq {|piece| piece.coordinates}).reject {|piece| piece.coordinates.nil?}
			bar = self.boardstate.pieces.reject {|piece| piece.coordinates.nil?}
			foo.each {|piece| bar.delete_at(bar.find_index(piece))}
			byebug unless bar.empty?
			pieces = self.boardstate.pieces.select {|piece| piece.coordinates == self.coordinates}
			piece = pieces.first
			piece
		else
			raise if arg
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
	def simulate(simlevel)
		simtile = Tile.new((self.coordinates.x_axis), (self.coordinates.y_axis), (self.depth - 1), self.game)
		simtile.sim_parent = self
		self.sim_child = self
		piece_sim = self.occupied_piece.simulate if self.occupied_piece
		piece_sim.sim_id = simtile.sim_id if piece_sim
		simlevel.pieces.push(piece_sim) if piece_sim
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
