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
