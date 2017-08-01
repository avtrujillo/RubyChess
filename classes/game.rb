class Game
	extend UserPrompt
	extend ChessDir
	attr_accessor :simlevels, :white_team, :black_team, :history, :pieces,
	:board, :tiles, :boardstate, :ended,  :white_player, :black_player, :saved
	attr_reader :name, :started, :winner, :game_over_cause, :final_move
	def initialize(white_player, black_player)
		@started = Time.now
		@white_player = white_player
		@black_player = black_player
		@black_team = Team.new("black", @black_player, self)
		@white_team = Team.new("white", @white_player, self)
		@pieces = self.create_starting_pieces
		raise if @pieces.uniq! {|piece| piece.coordinates}
		@simlevels = []
		@boardstate = Boardstate.new(self, @pieces, 0)
		@boardstate.pieces = @pieces.dup
		@board = @boardstate.board #the "board" attribute is a two-dimensional array of all tiles that is only used in the board_display function
		@tiles = @board.flatten
		@boardstate.moving_team = @white_team
		@simlevels.push(self.boardstate)
		Simlevel.new(self, [[]], 0)
		Simlevel.new(self, [[]], -1)
		@player_names = [@black_player.name, @white_player.name].sort
		@players = [white_player, black_player]
		@name = "#{@player_names[0]}_vs_#{@player_names[1]}_#{started}"
		@name = valid_windows_filename(@name)
		@players.each do |player|
			unless player.games.any?{|game| game.name == @name}
				player.games << self #reminder: update when saving or finishing
			end
		end
		@saved = false
		@history = []
		@winner = nil
	end
	def valid_windows_filename(str)
		replacements = {" " => "_", ":" => "-"}
		str = str.gsub(Regexp.union(replacements.keys), replacements)
	end
	def display_move_history
		@history.each {|move| puts move.summary}
	end
	def players
		@player_names.map do |name|
			Player.roster.find {|player| player.name == name}
		end
	end
	def player_names
		if @player_names
			return @player_names
		else
			@player_names = [@white_player.name, @black_player.name]
		end
	end
	def moving_team
		self.simlevels.first.moving_team
	end
	def play
		self.boardstate.generate_valid_moves
		self.saved = false
		$playing = true
		until $playing == false
			TurnMenu.new(self)
		end
	end
	def exit_game
		return false unless Game.yesno_prompt("Are you sure you want to quit")
		if Game.yesno_prompt("Would you like to save your game?")
			self.save
		end
		$playing = false
		true
	end
	def game_over(cause, winner)
		@ended = Time.now
		@game_over_cause = cause
		@final_move = @history.last
		@winner = winner
		self.save
		$playing = false
		if winner == "draw"
			puts "The game is a draw by #{game_over_cause}"
		else
			puts "#{winner.name} (#{winner.team.color}) wins by #{game_over_cause}"
		end
	end
	def save_directory
		game_dir = "/SaveData/Games"
		if self.ended
			return game_dir + "/Finished"
		elsif self.saved
			return game_dir + "/Unfinished"
		else
			return game_dir + "/Unsaved"
		end
	end
	def save(saved = true)
		self.saved = saved
		File.delete(@last_save_path) if @last_save_path
		Game.move_to_save_directory(self.save_directory)
		@last_save_path = "#{Dir.pwd}/#{self.name}.yaml"
		game_save = File.open("#{self.name}.yaml", "w")
		game_save.puts(YAML.dump(self))
		game_save.close
	end
	def self.load
		save_dir = File.dirname(File.expand_path(__FILE__))
		Game.move_to_save_directory(save_dir)
		players = Game.load_prompt
		return nil unless players
		game_name = self.select_save(players[0], players[1])
		return nil unless game_name
		Game.load_from_path(save_dir + game_name)
	end
	def self.load_from_path(file_path)
		game_file = File.open(file_path, "r")
		loaded_game = YAML.load(game_file.read)
		game_file.close
		loaded_game.saved = false
		loaded_game
	end
	PLAYERNAME_PROMPT_LAM = lambda do |response|
		return {valid: true, return: "back"} if response == "back"
		prev_dir = Dir.pwd
		self.move_to_save_directory("/Players")
		player = Player.search_roster(response)
		Dir.chdir(prev_dir)
		if player
			return {return: player}
		else
			return {error: "Sorry, I couldn't find that player"}
		end
	end
	def self.load_prompt
		players = []
		until players.count == 2
			prompt_message = "What is the name of Player #{players.count + 1}?\n"
			prompt_message += "You can also say \"back\" to cancel"
			player = self.prompt_until_valid(prompt_message, PLAYERNAME_PROMPT_LAM, nil)
			return nil if player == "back"
			players << player if player.is_a?(Player)
		end
		players
	end
	def self.select_save(player1, player2)
		saved_games = self.list_saves(player1, player2)
		(puts "\nNo matching games"; return nil) unless saved_games && !saved_games.empty?
		prompt_message = "What is the number of the game you want to load?\n"
		prompt_message += "You can also enter 0 to go back"
		game_index = (self.prompt_until_valid(prompt_message, SELECT_SAVE_LAM, nil,
		(0..saved_games.count).to_a) - 1)
		if game_index.negative?
			return nil
		else
			return saved_games[game_index]
		end
	end
	def self.list_saves(player1, player2)
		pstring1 = "#{player1.name} vs #{player2.name}"
		pstring2 = "#{player2.name} vs #{player1.name}"
		saved_games = []
		[pstring1, pstring2].each do |pstring|
			saved_games += Dir.entries(Dir.pwd).select {|save|
				save.length > pstring.length &&
				save[0...pstring.length].to_s == pstring
			}
		end
		saved_games.each do |save|
			print "#{(saved_games.index(save) + 1).to_s}. "
			puts "#{save}"
		end
		saved_games
	end
	SELECT_SAVE_LAM = lambda do |response, valid_ints|
		resp_int = response.to_i
		if resp_int.to_s == response && valid_ints.include?(resp_int)
			return {valid?: true, return: resp_int}
		elsif resp_int.to_s == response
			return {valid?: false, error: "Out of range"}
		else
			return {valid?: false, error: "Please respond with an integer"}
		end
	end
	def self.find_all_saves(save_dir = "/SaveData/Games/Unfinished")
		Game.move_to_save_directory(save_dir)
		save_file_names = Dir.entries(Dir.pwd)
		save_file_names.select! {|entry| entry.length > 5 && entry[-5..-1] = ".yaml"}
		saved_games = save_file_names.map do |name|
			save_file = File.open(name, "r")
			game = nil
			if save_file.is_a?(File) && !File.directory?(save_file)
				game = YAML.load(save_file.read)
			else
				game = nil
			end
			save_file.close
			game
		end
		saved_games.select! {|game| game.is_a?(Game)}
		saved_games.each {|game| raise unless game.is_a?(Game)}
		saved_games
	end
	def create_starting_pieces #returns an array of all pieces in their starting postions
		pieces = [
		Rook.new("white", "A1", 1, self, 0),
		Knight.new("white", "B1", 1, self, 0),
		Bishop.new("white", "C1", 1, self, 0),
		Queen.new("white", "D1", 1, self, 0),
		King.new("white", "E1", 1, self, 0),
		Bishop.new("white", "F1", 2, self, 0),
		Knight.new("white", "G1", 2, self, 0),
		Rook.new("white", "H1", 2, self, 0),
		Pawn.new("white", "A2", 1, self, 0),
		Pawn.new("white", "B2", 2, self, 0),
		Pawn.new("white", "C2", 3, self, 0),
		Pawn.new("white", "D2", 4, self, 0),
		Pawn.new("white", "E2", 5, self, 0),
		Pawn.new("white", "F2", 6, self, 0),
		Pawn.new("white", "G2", 7, self, 0),
		Pawn.new("white", "H2", 8, self, 0),
		Rook.new("black", "A8", 1, self, 0),
		Knight.new("black", "B8", 1, self, 0),
		Bishop.new("black", "C8", 1, self, 0),
		Queen.new("black", "D8", 1, self, 0),
		King.new("black", "E8", 1, self, 0),
		Bishop.new("black", "F8", 2, self, 0),
		Knight.new("black", "G8", 2, self, 0),
		Rook.new("black", "H8", 2, self, 0),
		Pawn.new("black", "A7", 1, self, 0),
		Pawn.new("black", "B7", 2, self, 0),
		Pawn.new("black", "C7", 3, self, 0),
		Pawn.new("black", "D7", 4, self, 0),
		Pawn.new("black", "E7", 5, self, 0),
		Pawn.new("black", "F7", 6, self, 0),
		Pawn.new("black", "G7", 7, self, 0),
		Pawn.new("black", "H7", 8, self, 0) ]
	end
end
