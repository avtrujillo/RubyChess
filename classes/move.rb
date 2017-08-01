class Move
	attr_accessor :departure, :piece, :destination, :taken, :team, :enemy, :turn,
	:extras, :game_end, :snapshot, :previous_turn, :following_turn, :game,
	:ally_check_cache, :enemy_check_cache, :first_move, :simlevel, :outcome_cache,
	:boardstate_before, :boardstate_after
	def initialize(game, departure, destination)
		@game = game
		@departure = departure #the tile the moving piece is leaving from
		@piece = departure.occupied_piece
		@team = @piece.team
		@simlevel = @game.simlevels.find {|level| level.depth == @piece.depth}
		@destination = destination #the tile the moving piece is arriving at
		@taken = destination.occupied_piece unless @destination == "castle"
		@enemy = @piece.team.opposite
		@turn = game.boardstate.turn_counter
		@first_move = @piece.moved
		self.simulate_outcomes
		# @ snapshot is taken at the END of the move
		# @check_cache will be used to cache the results of check_detect as needed
	end
	def summary
		sumry = "\nMove ##{self.move_number}: #{team.player.name} moves their #{piece.title}"
		sumry += "from #{departure.name} to #{destination.name}. Check = #{!!self.enemy_check}"
		sumry += "#{taken.name} taken" if taken
		sumry
	end
	def move_number
		found_move = game.history.find {|move| move.turn == self.turn}
		ind = (self.game.history.find_index {|move| move === found_move})
		return game.history.count if ind.nil?
		ind + 1
	end
	def ===(move)
		return false unless move.is_a?(Move)
		return false unless move.piece.name == self.piece.name
		return false unless move.destination.coordinates == self.destination.coordinates
		return false unless move.departure.coordinates == self.departure.coordinates
		return false unless move.taken.name == self.taken.name
		true
	end
	def white_check
		if self.team == self.game.white_team
			return self.ally_check
		else
			return self.enemy_check
		end
	end
	def black_check
		if self.team == self.game.black_team
			return self.ally_check
		else
			return self.enemy_check
		end
	end
	def ally_check #if friendly_check_detect has been not performed before, run it; else return the cached value
		if self.ally_check_cache.nil?
			return self.ally_check_detect
		else
			return self.ally_check_cache
		end
	end
	def enemy_check
		if self.piece.is_a?(Pawn) && self.enemy_check_cache.nil? &&
			[1, 8].include?(self.destination.coordinates.y_axis) &&
			!self.piece.simlevel.pieces.any? {|piece| piece.promoted_from && piece.promoted_from == self.piece.name}
			!self.outcome.pieces.any? {|piece| piece.promoted_from && piece.promoted_from == self.piece.name} &&
			self.piece.coordinates
			return self.promotion_check_detect
		elsif self.enemy_check_cache.nil?
			return self.enemy_check_detect
		else
			return self.enemy_check_cache
		end
	end
	def ally_check_detect
		outcome = self.outcome.dup
		possible_moves = outcome.generate_valid_moves
		check_moves = possible_moves.select {|move| raise unless move.is_a?(Move); move.taken.is_a?(King)}
		if check_moves.empty?
			self.ally_check_cache = false
		else
			self.ally_check_cache = check_moves
			raise if check_moves.any?{|move| !move.is_a?(Move)}
		end
		self.ally_check_cache
	end
	def enemy_check_detect(outcome = self.outcome)
		outcome.moving_team = outcome.moving_team.opposite #we proceed as though the moving team gets another free turn
		possible_moves = outcome.generate_valid_moves
		check_moves = possible_moves.select {|move| raise unless move.is_a?(Move); move.taken.is_a?(King)}
		outcome.moving_team = outcome.moving_team.opposite
		if check_moves.empty?
			return self.enemy_check_cache = false
		else
			return self.enemy_check_cache = check_moves
		end
	end
	def promotion_check_detect
		check_moves = [Queen, Knight].inject([]) do |ch_moves, klass| # there are no situations where promoting to a rook or bishop would result in check but promoting to a queen wouldn't.
			promotion_outcome = self.outcome
			to_be_promoted = promotion_outcome.pieces.find do |piece|
				piece.name == self.piece.name
			end
		#	raise if to_be_promoted.coordinates.nil?
			to_be_promoted.promote(klass, self)
			ecd = self.enemy_check_detect(promotion_outcome)
			ch_moves += ecd if ecd
			ch_moves
		end
		raise if check_moves.any? {|move| !move.is_a?(Move)}
		self.enemy_check_cache = (check_moves.empty? ? false : check_moves)
	end
	def outcome
		if @outcome_cache
			return @outcome_cache
		else
			return @outcome_cache = self.simulate_outcome
		end
	end
	def simulate_outcome
		simlevel = self.game.simlevels.find {|level| (level.depth == self.piece.depth)}
		return simlevel if self.game.history.include?(self) && simlevel
		simstate = simlevel.simulate
		if self.destination == "castle"
			self.simulate_castle(simstate)
		else
			self.simulate_move(simstate)
		end
		simstate
	end
	def simulate_castle(simstate)
		rook = simstate.pieces.find {|piece| piece.name == self.piece.name}
		rook_destination = self.piece.castle_dest
		raise unless rook.is_a?(Rook)
		king = simstate.friendly_king
		king_destination = rook.castle_path.king_dest
		raise unless king.is_a?(King)
		king.move_to(king_destination.coordinates)
		rook.move_to(rook_destination.coordinates)
		simstate.moving_team = simstate.moving_team.opposite
	end
	def simulate_move(simstate)
		moved_piece = simstate.pieces.find {|piece| piece.same_promotion_or_sim?(self.piece)}
		#byebug unless moved_piece
		if self.piece.is_a?(Pawn) && moved_piece.nil? &&
			[1, 8].include?(destination.coordinates.y_axis)
			moved_piece = simstate.pieces.find do |piece|
				piece.promoted_from == (self.piece.promoted_from || self.piece.name)
			end
		end
		moved_piece.move_to(self.destination.coordinates)
		simstate.moving_team = simstate.moving_team.opposite
	end
	def execute
		self.enemy_check
		self.previous_turn = self.game.history.last
		self.previous_turn.following_turn = self if self.previous_turn
		puts "#{self.team.color.upcase} moves their #{self.piece.class.to_s} from #{self.departure.coordinates.name} to #{self.destination.coordinates.name}."
		puts "#{self.team.color.capitalize}'s #{self.piece.class.to_s} has taken #{self.enemy.color}'s' #{self.taken.class.to_s}" if self.taken
		self.piece.move_to(self.destination)
		if (self.piece.is_a?(Pawn) && [1, 8].include?(self.destination.coordinates.y_axis))
			self.piece.promotion_conditions(self)
		end
		self.game.history.push(self)
		self.simlevel.turn_counter += 1
		self.piece.moved = true
		self.simlevel.moving_team = self.simlevel.moving_team.opposite
		self.snapshot = Snapshot.new(self.simlevel)
		self.mate_detect
		self.three_move_rule
		self.fifty_move_rule
		if self.enemy_check
			puts "#{self.enemy.color}'s king is in check from:"
			enemy_check.each {|m| raise unless (m.is_a?(Move) || (m.count == 1 && m.first.is_a?(Move))); puts m.summary}
		end
	end
	def mate_detect
		self.simlevel.generate_valid_moves
		valid_move = self.simlevel.movelist.find {|found_move| !found_move.ally_check}
		self.outcome.generate_valid_moves
		valid_move2 = self.outcome.movelist.find {|found_move| !found_move.ally_check}
		if self.enemy_check && !valid_move # aka checkmate
			self.game.game_over("checkmate", self.team.player)
		elsif !valid_move # aka stalemate
			self.game.game_over("stalemate", self.team.player)
		end
	end
	def three_move_rule
		identical_moves = self.game.history.select {|past_move| (past_move.snapshot == self.snapshot)}
		if identical_moves.count == 2
			puts "The board has already been in this state before. If this happens\nagain, the game will result in a draw."
		elsif identical_moves.count == 3
			puts "The board has been in this state three times. The game ends in a draw."
			self.game.game_over("three moves", "draw")
		end
	end
	def fifty_move_rule
		# reminder: this should allow either player to declare a draw rather than force one on both of them
		fmc = self.simlevel.fifty_move_counter
		fmc += 1 unless self.taken || self.piece.is_a?(Pawn)
		if fmc == 50
			self.game.game_over("fifty moves", "draw")
		elsif fmc > 19 && (fmc % 10 == 0) || (50 - fmc < 10)
			puts "It has been #{fmc.to_s} moves since a pawn has been"
			puts "moved or a piece has been taken."
			puts "If no piece is captured or pawn moved in the next"
			puts "#{(50 - fmc).to_s} turns, the game will end in a draw."
		end
	end
	def completed?
		if @game.history.include?(self)
			return true
		else
			return false
		end
	end
end
