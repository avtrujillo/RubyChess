class MainMenu
	extend UserPrompt
	extend ChessDir
	attr_accessor :game, :first_negquery
	def initialize
		MainMenu.chdir_or_mkdir_all
		@first_negquery = true
		self.negquery
		self.main_menu_prompt
	end
	def negquery
		Boardstate.new(nil, nil).display
		if self.first_negquery == true
			puts "Hi, welcome to chess!"
			puts "Before we begin I need your help to set the display.\n"
		end
		until MainMenu.yesno_prompt("In the above board, does tile A1 appear black?\n") do
			$neg_display = !$neg_display
			Boardstate.new(nil, nil).display
			puts "How about now?"
		end
		self.first_negquery_message
	end
	def first_negquery_message
		if self.first_negquery == true
			puts "\nGood. Let's get started then."
			self.first_negquery = false
		end
	end
	MAIN_MENU_LAM = lambda do |response, valid|
		if valid.include?(response) || response == "close"
			return {return: response}
		else
			return nil
		end
	end
	def unsaved_game_prompt
		unsaved_game = get_unsaved_game
		load_message = "I see that you had an unsaved game when the program last "
		load_message += "closed.\nWould you like to resume it?"
		save_message = "Would you like to save it then?"
		if unsaved_game && MainMenu.yesno_prompt(load_message)
			Game.load_from_path(unsaved_game).play
		elsif unsaved_game && MainMenu.yesno_prompt(save_message)
			Game.load_from_path(unsaved_game).save
		elsif unsaved_game
			File.delete(unsaved_game)
		end
	end
	def get_unsaved_game
		unsaved_dir = __dir__ + "/SaveData/Games/Unsaved"
		unsaved_dir_entries = Dir.entries(unsaved_dir)
		unsaved_dir_entries.select! {|entry| entry[-5..-1] == ".yaml"}
		raise "multiple unsaved games" if unsaved_dir_entries.count > 1
		return nil if unsaved_dir_entries.empty?
		unsaved_dir + "/" + unsaved_dir_entries.first
	end
	def main_menu_prompt #asks the user for prompts when the program is first opened or after a game is completed
		unsaved_game_prompt
		loop do
			valid = ["new game", "load game", "view scoreboard",
				"change display colors", "close"]
			message = "\nWhat would you like to do? You can say\n"
			message += "#{valid.join(", ")} or \"close\""
			response = MainMenu.prompt_until_valid(message, MAIN_MENU_LAM, nil, valid)
			break if response == "close"
			main_menu_execute(response)
		end
	end
	def main_menu_execute(response)
		case response
		when "new game"
			self.start_new_game
		when "view scoreboard"
			Scoreboard.display_menu
		when "change display colors"
			self.negquery
		when "load game"
			loaded_game = Game.load
			loaded_game.play if loaded_game
		end
	end
	def player_name_prompt
		loop do
			puts %Q(What is the white player's name?\n(To assign an AI to white team, enter the name "AI"))
			white_player_name = gets.chomp.upcase
			puts %Q(What is the black player's name?\n(To assign an AI to black team, enter the name "AI"))
			black_player_name = gets.chomp.upcase
			if (black_player_name != white_player_name) || black_player_name == "AI"
				return {"white" => white_player_name, "black" => black_player_name}
			end
			puts "Sorry, both teams cannot have the same player."
		end
	end
	def start_new_game
		player_names = self.player_name_prompt
		white_name = player_names["white"]
		black_name = player_names["black"]
		black_player = Player.create_or_load("black", black_name)
		white_player = Player.create_or_load("white", white_name)
		self.game = Game.new(white_player, black_player)
		self.game.play
	end
end
