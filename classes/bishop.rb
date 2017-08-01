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
