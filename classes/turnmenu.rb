class TurnMenu
	extend UserPrompt
	attr_accessor :game, :boardstate
	def initialize(game)
		@game = game
		@boardstate = game.boardstate
		self.ai_or_human
	end
	def ai_or_human
		self.game.save(false)
		moving_player_name = self.boardstate.moving_team.player.name
		if moving_player_name.upcase == "AI"
			self.ai_move
		else
			self.human_prompt
		end
	end
	def ai_move
		movelist = self.boardstate.movelist.select {|move| !move.ally_check}
		movelist.sample.execute
	end
	def human_prompt_message
		self.boardstate.display
		puts "It is #{self.boardstate.moving_team.player.name}'s turn."
		puts "What is the coordinate of the piece I should move?"
		puts %Q(Please reply in the form of a coordinate, e.g. "B2".)
		puts %Q(You can also: say "surrender" to surrender,)
		puts %Q("draw" to agree to a draw, "move history" to view move history,)
		puts %Q(or "exit" to exit the game with or without saving.)
	end
	def human_prompt
		loop do
			movelist = self.boardstate.movelist.dup
			self.human_prompt_message
			response = gets.chomp.upcase
			if (response.length == 2)
				self.human_move(response, movelist)
				break
			elsif response == "MOVE HISTORY"
				@game.display_move_history
			elsif response == "SURRENDER"
				self.game.game_over("surrender", @game.moving_team.opposite.player)
				break
			elsif response == "DRAW"
				self.draw_prompt
				break
			elsif response == "EXIT"
				return "game exited" if self.boardstate.game.exit_game
				break
			else
				puts "Sorry, I didn't understand that."
			end
		end
	end
	def human_move(response, movelist)
		departure = self.boardstate.tiles.find {|tile|
			tile.coordinates.name == response
		}
		if departure
			movelist.select! {|found_move| found_move.departure.coordinates.name == response} #the list of possible moves will now only contain moves from the specified tile
			self.destination_prompt(departure, movelist)
		else
			self.boardstate.display
			puts "Sorry, that's not a valid coordinate."
		end
	end
	def destination_prompt(departure, movelist)
		if movelist.empty?#displays error messages if the specified coordinate has no valid moves
			self.empty_movelist_message(departure)
		else
			puts "Where would you like to move it to?"
			can_castle = false
			if movelist.find {|found_move| ((found_move.departure == departure) && (found_move.destination == "castle"))}
				puts %Q(You can also say "castle" to castle.)
				can_castle = true
			end
			response = gets.chomp.upcase
			if (!response.casecmp("castle") && can_castle)
				departure.occupied_piece.castle
			elsif !self.boardstate.tiles.any? {|tile| tile.coordinates.name == response}
				self.boardstate.display
				puts "Sorry, that's not a valid coordinate."
			else
				self.normal_move(departure, movelist, response)
			end
		end
	end
	def normal_move(departure, movelist, response)
		destination = self.boardstate.tiles.find {|tile| tile.coordinates.name == response}
		move = movelist.find {|found_move| found_move.destination.coordinates.name == response}
		if move.nil? && (!destination.occupied_piece || (destination.occupied_piece.team != boardstate.moving_team))
			self.boardstate.display
			puts "Sorry, that's not a valid move for that piece."
		elsif move.nil? && (destination.occupied_piece && destination.occupied_piece.team == boardstate.moving_team)
			puts "Sorry, that tile is already occupied by a friendly piece."
			self.boardstate.display
		elsif move.ally_check
			self.boardstate.display
			puts "Sorry, that move would put your king in check."
		else
			move.execute
		end
	end
	def empty_movelist_message(departure)
		self.boardstate.display
		if departure.occupied_piece.nil?
			puts "Sorry, that tile is unoccupied."
		elsif departure.occupied_piece.team != self.boardstate.moving_team
			puts "Sorry, the piece belongs to the other player."
		else
			puts "Sorry, that piece has no valid moves."
		end
	end
	def draw_prompt
		prompt_message = "Do both players agree to a draw?" #future improvement: maybe have some mechanism to ask both players?
		self.game.game_over("agreed to draw", "draw") if TurnMenu.yesno_prompt(prompt_message)
	end
end
