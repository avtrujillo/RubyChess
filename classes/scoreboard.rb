class Scoreboard
	extend UserPrompt
	attr_accessor :games
	attr_reader :player1, :player2, :players, :games, :draws, :unfinished,
	:player_1_wins, :player_2_wins, :player_1_wins_white, :player_1_wins_black
	def initialize(player1, player2)
		@player1 = player1
		@player2 = player2
		@players = [player1, player2]
		@games = player1.games.select {|game| game.player_names.include?(player2.name)}
		@player_1_wins = games.select {|game| game.winner == player1}
		@player_1_wins_white = @player_1_wins.select {|game| game.winner.color == "white"}
		@player_1_wins_black = @player_1_wins.select {|game| game.winner.color == "black"}
		@player_2_wins = games.select {|game| game.winner == player2}
	 	@draws = games.select {|game| game.winner == "draw"}
		@unfinished = games.select {|game| game.winner == "dnf" || game.winner.nil?}
	end
	def display
		puts "\n#{@player1.name} vs #{@player2.name}"
		puts @player_1_wins.count.to_s + "-" + @player_2_wins.count.to_s
		p1_losses_white = (@player_1_wins.count - @player_1_wins_white.count).to_s
		puts "With #{@player1.name} as white: #{@player_1_wins_white.count.to_s}-#{p1_losses_white}"
		p1_losses_black = (@player_1_wins.count - @player_1_wins_black.count).to_s
		puts "With #{@player1.name} as black: #{@player_1_wins_black.count.to_s}-#{p1_losses_black}"
		puts @draws.count.to_s + " draws"
		puts @unfinished.count.to_s + " unfinished\n"
	end
	DISP_PROMPT_LAM = lambda do |response|
		if ["all", "compare", "back"].include?(response.downcase!)
			return {return: response}
		else
			return nil
		end
	end
	def self.display_prompt
		message = "If you would like to view the entire scoreboard, say \"all\"\n"
		message += 'If you would like to compare only two players, say "compare"'
		message += "\nYou can also say \"back\" to go back"
		disp_prompt_lam = lambda do |response|
			response.downcase!
			validity = ["all", "compare", "back"].include?(response)
			validity ? (return {return: response}) : (return nil)
		end
		self.prompt_until_valid(message, disp_prompt_lam, nil)
	end
	def self.display_menu
		response = self.display_prompt
		if response == "all"
			Scoreboard.display_all
		elsif response == "compare"
			players = Scoreboard.compare_prompt
			Scoreboard.new(players[0], players[1]).display
		elsif response == "back"
			return nil
		end
	end
	def self.display_all
		player_pairs =	Player.roster.permutation(2).to_a
		player_sort = Proc.new {|player1, player2| player1.name <=> player2.name}
		player_pairs.uniq! {|pair| pair.sort(&player_sort)}
		player_pairs.each {|pair| Scoreboard.new(pair[0], pair[1]).display}
	end
	def self.compare_prompt
		compare_lam = lambda do |name|
			player = Player.search_roster(name.upcase)
			player ? (return {return: player}) : (return nil)
		end
		[1, 2].map do |n|
			ord = Odrinal.ordinal_string_from_int(n)
			prompt_message = "What is the name of the #{ord} player?"
			prompt_until_valid(prompt_message, compare_lam, nil)
		end
	end
end
