class Team
	attr_accessor :color, :player, :kings, :check, :game
	def initialize(color, player, game)
		@color = color
		@player = player
		@game = game
		@check = false #is this team's king currently in check?
	end
	def kings # gives us an easy way of finding the king for any given simlevel
		king_array = self.game.pieces.select {|piece| piece.is_a?(King)}
		king_array.sort_by{|king| king.depth.abs}
	end
	def king
		return self.kings[0]
	end
	def sim_king
		return self.kings[-1]
	end
	def metasim_king
		return self.kings[-2]
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
