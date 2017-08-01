class King < Piece
	@white_symbol = "♚"
	@black_symbol = "♔"
	def initialize(color, tilename, serial, game, depth = 0)
		super(color, tilename, serial, game, depth)
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
