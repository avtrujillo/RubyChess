class Rook < Piece
	attr_accessor :castle_path, :castle_dest, :castle_tiles
	@white_symbol = "♜"
	@black_symbol = "♖"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
	end
	def can_castle?
		king = self.team.kings[self.depth.abs]
		both_unmoved = (self.moved == false && king.moved == false) # have the king or rook or both been moved yet?
		return false unless both_unmoved
		self.castle_path = CastlePath.new(self)
		self.castle_tiles = @castle_path.rook_tiles
		self.castle_dest = @castle_tiles.last
		clear = self.castle_path.clear?
		safe = self.castle_path.safe?
		last_move_check = game.history.last ? game.history.last.enemy_check : false
		(safe && !last_move_check)
	end
	def criteria
		if (self.depth > 2) && (self.serial < 3) && self.can_castle? #the former condition is in place to prevent infinite loops where check detect simulates castling as a possible move, which in turn must run check detect
			self.simlevel.movelist.push(Move.new(self.game, self.tile, "castle"))
		end
		self.plus_path
	end
	def castle(move)
		move.previous_turn = move.game.history.last
		move.previous_turn.following_turn = move
		puts "#{move.team.color.capitalize} castles from #{move.departure.cordinates.name}."
		move.piece.move_to(destination.coordinates)
		king = move.simlevel.king
		king_destination = self.castle_path.king_dest
		king_departure = king.tile # reminder: do we need this?
		king.move_to(king_destination.coordinates)
		move.game.history.push(move)
		move.simlevel.turn_counter += 1
		move.piece.moved = true
		move.simlevel.moving_team = move.team.opposite
		move.snapshot = Snapshot.new(move.simlevel)
		move.simlevel.generate_valid_moves
		if !move.simlevel.movelist.find {|found_move| !found_move.ally_check}
			mate_type = move.enemy_check ? "checkmate" : "stalemate"
			self.game.game_over(mate_type, "draw")
		elsif move.enemy_check
			puts "#{move.team.color}'s king is in check from:"
			move.enemy_check.each {|m| puts m.summary}
		end
	end
end
