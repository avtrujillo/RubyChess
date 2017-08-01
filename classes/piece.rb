class Piece
	extend UserPrompt
	include Simulations
	attr_accessor :promoted_from, :coordinates, :serial, :depth, :game, :moved, :color
	class << self; attr_accessor :black_symbol, :white_symbol end
	@white_symbol = "?"
	@black_symbol = "?"
	def initialize(color, tilename, serial, game, depth = 0)
		@depth = depth
		@color = color
		@game = game
		@coordinates = $coordinates.find {|coor| coor.name == tilename.upcase}
		raise unless @coordinates
		self.clear_tile if @game && @game.simlevels && @game.simlevels.count >= (self.depth.abs + 1)
		@serial = serial
		@moved = false
		raise if self.game && self.game.simlevels && self.simlevel.pieces.uniq! {|piece| piece.coordinates}
	end
	def ==(other_piece)
		(other_piece.is_a?(self.class) && other_piece.name == self.name &&
		self.depth == other_piece.depth && self.same_sim?(other_piece) &&
		self.game.name == other_piece.game.name)
	end
	def ===(other_piece)
		(other_piece.is_a?(self.class) && other_piece.name == self.name &&
		self.depth == other_piece.depth && self.same_sim?(other_piece) &&
		self.game.name == other_piece.game.name)
	end
	def same_or_promoton?(other_piece)
		# used to keep track of piece identity after promotion
		# returns true if other_piece is the same piece, if one piece was promoted
		# from the other, or if both pieces were promoted from the same piece
		(other_piece.is_a?(self.class) && self.depth == other_piece.depth &&
		self.game.name == other_piece.game.name &&
		(self.name == other_piece.name || self.name == other_piece.promoted_from ||
		self.promoted_from == other_piece.name ||
		other_piece.promoted_from == self.promoted_from))
	end
	def same_promotion_or_sim?(other_piece)
		# same as "same_or_promoton" except it doesn't require the depths to match
		(other_piece.is_a?(self.class) && self.game.name == other_piece.game.name &&
		(self.name == other_piece.name || self.name == other_piece.promoted_from ||
		self.promoted_from == other_piece.name ||
		other_piece.promoted_from == self.promoted_from))
	end
	def clear_tile
		current_occupants = self.simlevel.pieces.select {|piece|
			piece.coordinates == self.coordinates && !(piece.equal?(self))
		}
		current_occupants.each do |piece|
			raise if piece.name == self.name
			piece.coordinates = nil
			raise if self.coordinates.nil? || self.nil?
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
			return self.class.white_symbol
		else
			return self.class.black_symbol
		end
	end
	def simlevel
		self.game.simlevels[self.depth.abs]
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
		piece_sim.promoted_from = self.promoted_from
		piece_sim.sim_parent = self
		self.sim_child = piece_sim
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
		dest = dest.coordinates if dest.is_a?(Tile)
		dest_tile = self.simlevel.find_tile(dest)
		if dest_tile.occupied_piece && dest_tile.occupied_piece != self
			dest_tile.occupied_piece.coordinates = nil
		end
		self.coordinates = dest_tile.coordinates
		self.moved = true
	end
end
