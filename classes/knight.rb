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
