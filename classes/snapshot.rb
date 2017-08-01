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
