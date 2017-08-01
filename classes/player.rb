class Player
	extend ChessDir
	attr_accessor :color, :name, :games
	@@roster = []
	def initialize(color, name)
		@color = color #this may change from game to game
		@name = name.upcase
		@games = Array.new
		@@roster.push(self)
		Player.sync_players
	end
	def game
		self.games.find {|game| game.player.object_id == self.object_id}
	end
	def update_games
		@games = [] if @games.nil?
		self_game_names = @games.map {|game| game.name}
		saved_games = Game.find_all_saves
		saved_games.select! {|game|
			raise "#{game.name}" unless game.player_names
			game.player_names.include?(self.name)
		}
		to_be_added = saved_games.select {|game|
			!self_game_names.include?(game.name)
		}
		@games += to_be_added
	end
	def team
		if self.game.white_team.player == self
			return self.game.white_team
		elsif self.game.black_team.player == self
			return self.game.black_team
		else
			raise "couldn't find team"
		end
	end
	def opposite_player_name(game)
		game.player_names.find {|name| name != self.name}
	end
	def self.search_roster(name)
		Player.sync_players
		@@roster.find {|player| player.name == name.upcase}
	end
	def self.roster
		Player.sync_players
		@@roster
	end
	def self.create_or_load(color, name)
		Player.sync_players
		existing_player = @@roster.find {|player| player.name == name}
		if existing_player
			return existing_player
		else
			return Player.new(color, name)
		end
	end
	def self.sync_players
		saved_players = self.load_players
		@@roster.each do |existing_player|
			saved_player = saved_players.find {|saved| saved.name == existing_player.name}
			if saved_player.nil?
				existing_player.update_games
				saved_players.push(existing_player)
			else
				existing_player.update_games
				saved_players[saved_players.index(saved_player)] = existing_player
			end
		end
		@@roster = saved_players
		@@roster.each {|player| player.update_games}
		@@roster.sort_by!{|player| player.name}
		self.save_players
	end
	def self.save_players
		Player.move_to_save_directory("/SaveData/Players")
		players_file =  File.open("players.yaml", "w")
		players_file.puts YAML.dump(@@roster)
		players_file.close
	end
	def self.load_players
		Player.move_to_save_directory("/SaveData/Players")
		if File::exists?("players.yaml")
			players_file = File.open("players.yaml", "r")
			players_text = players_file.read
			players_file.close
			return YAML.load(players_text)
		else
			return []
		end
	end
end
