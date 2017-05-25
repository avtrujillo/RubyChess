# the word "bug" in comments will be used to flag unfixed bugs

require_relative('./Ordinals')
require 'yaml'

module ChessDir
	public
	def chdir_or_mkdir(dir_arg)
		dir_arg = dir_arg[1..-1] if dir_arg [0] == "/"
		Dir.chdir(File.dirname(__dir__ + "/" + dir_arg))
		arg_basename = dir_arg.split("/").last
		begin
			Dir.chdir("./#{arg_basename}")
		rescue
			Dir.mkdir(arg_basename)
		end
	end
	def chdir_or_mkdir_all
		save_dirs = ["/SaveData", "/SaveData/Games", "/SaveData/Games/Unsaved",
		"/SaveData/Games/Unfinished", "/SaveData/Games/Finished", "/SaveData/Players"]
		save_dirs.each {|save_dir| self.chdir_or_mkdir(save_dir)}
	end
	def move_to_save_directory(save_dir)
		path_array = save_dir.split("/")
		if (path_array.last == "Players") || path_array.last == "Games"
			Dir.chdir(__dir__ + "/SaveData/" + path_array.last)
		elsif ["Unfinished", "Unsaved", "Finished"].include?(path_array.last)
			Dir.chdir(__dir__ + "/SaveData/Games/" + path_array.last)
		else
			raise "invalid save destination"
		end
	end
end

$needs_testing = false #used for debugging

$neg_display = true # controls whether or not to invert the black and white colors in the display

module UserPrompt
	def yesno_prompt(message)
		loop do
			puts message
			response = gets.chomp.downcase
			if response == "yes"
				return true
			elsif response == "no"
				return false
			else
				puts "Sorry, I didn't understand that."
				redo
			end
		end
	end
	def open_ended_prompt(prompt_message)
		raise "message must be a string" unless prompt_message.is_a?(String)
		puts prompt_message
		response = gets.chomp
	end
	def prompt_until_valid(prompt_message, lam, err_message, *args)
		err_message = "Sorry, I didn't understand that" if err_message.nil?
		loop do
			response = open_ended_prompt(prompt_message)
			lam_hash = lam.call(response, *args)
			if lam_hash && (lam_hash[:return] || lam_hash[:valid?])
				return (lam_hash[:return])
			else
				puts (lam_hash.nil? ? err_message : lam_hash[:error])
			end
		end
	end
end


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

class Coordinates
	attr_accessor :x_axis, :y_axis, :letter, :name
	def initialize(text)
		@letter = text.chop.upcase #isolates the letter in the coordinates
		@y_axis = text.reverse.chop.to_i #isolates the y-coordinate
		@x_axis = self.class.letter_to_x(@letter) #changes the letter to a row number
		@name = text
		$coordinates.push(self)
	end
	ALPH = ["taken", "A", "B", "C", "D", "E", "F", "G", "H"]# used to translate between letter and row number
	def self.x_to_letter(x_coordinate) #converts x coordinates to letters
		ALPH[x_coordinate]
	end
	def self.letter_to_x(letter) #converts letters to x coordinates
		ALPH.index(letter)
	end
	def self.alphanum_to_num(text) #for converting e.g. "A1" to "(1, 1)"
		letter = text.chop.downcase #isolates the letter in the coordinates
		y_axis = text.reverse.chop.to_i #isolates the y-coordinate
		x_axis = self.letter_to_x(letter) #translates the letter to an x-coordinate
		[x_axis, y_axis]
	end
	def self.num_to_alphanum(x_axis, y_axis) #for converting e.g. "(1, 1)" to "A1"
		letter = self.x_to_letter(x_axis) #translates the x-coordinate to a letters
		letter + y_axis.to_s #combines the letter and y-coordinate to create a single name
	end
	def ==(other)
		return false unless other.is_a?(Coordinates)
		return false unless other.y_axis == self.y_axis
		return false unless other.x_axis == self.x_axis
		true
	end
end

$coordinates = []

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
		@simlevels = []
		@boardstate = Boardstate.new(self, @pieces, 0)
		@board = @boardstate.board #the "board" attribute is a two-dimensional array of all tiles that is only used in the board_display function
		@tiles = @board.flatten
		@boardstate.moving_team = @white_team
		@simlevels.push(self.boardstate)
		@simlevels.push(Simlevel.new(self, [[]], 0))
		@simlevels.push(Simlevel.new(self, [[]], -1))
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
		save_dir = (File.expand_path(__FILE__) - "RubyChess.rb")
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

class Boardstate #redundant, but makes things easier to read
	attr_accessor :game, :tiles, :board, :pieces, :depth, :turn_counter,
	:moving_team, :fifty_move_counter, :game_over, :movelist
	def initialize(game, pieces, depth = 0)
		@game = game
		@board = self.board_create(@game)
		@tiles = board.flatten #remember, these are to reflect only the attributes of the game at the time of creation
		@pieces = pieces
		@depth = depth
		@turn_counter = 0
		@fifty_move_counter = 0
		@game_over = false #reminder: do we need this? If so, should it be moved to game instead?
		@movelist = [] #list of all possible valid moves for the next turn
	end
	def board_create(game = nil) #generates all 64 tiles of the board
		board = []
		for x in (1..8) # makes an array for each row of tiles
			board.push([])
		end
		board.each do |row| #adds 8 tiles with the appropriate coordinates to each row
			for x in (1..8)
				tile = Tile.new(x, (board.index(row) + 1), 0, game)
				row.push(tile)
			end
		end
		return board
	end
	def white_king
		self.pieces.find {|piece| piece.title == "white king"}
	end
	def black_king
		self.pieces.find {|piece| piece.title == "black king"}
	end
	def active_pieces # pieces that have not been taken
		pieces.select {|piece| piece.coordinates} # taken pieces have nil coordinates
	end
	def friendly_king
		if self.moving_team == self.game.white_team
			return self.white_king
		else return self.black_king
		end
	end
	def enemy_king
		if self.moving_team == self.game.white_team
			return self.black_king
		else
			return self.white_king
		end
	end
	def go_deeper
		sublevel = game.simlevels.find {|level| level.depth == (@depth - 1)}
		return sublevel
	end
	def simulate
		deeper = Simlevel.new(self.game, self.board, self.depth)
		if self.game.simlevels.count < self.depth.abs + 2 && self.game.simlevels.count >= 3
			self.game.simlevels.push(deeper)
		elsif self.game.simlevels.count >= (self.depth.abs + 2)
			self.game.simlevels[self.depth.abs + 1] = deeper
		end
		return deeper
	end
	def record
		return Snapshot.new(self)
	end
	def taken_pieces
		return pieces.select {|piece| piece.coordinates == nil}
	end
	def legend
		rows = []
		if self.pieces
			self.pieces.each do |piece|
				rows.push ("   #{piece.title}=#{piece.symbol}" )
			end
			rows.uniq!
			rows.sort!
		end
		rows
	end
	def display #each tile is represented by a 3x3 grid of characters, with the icon of the occupying piece in the center
		legend = self.legend
		self.board.reverse.each do |row| # I know this is sloppy and I should go back and put the board in the right order in the first place, but whatever
			self.print_row(self.board, row, legend)
		end
		puts " | A  B  C  D  E  F  G  H |" #the letters corresponding to the x-coordinates of the tiles, displayed below the board
	end
	def print_row(board, row, legend)
		rowbread = "  " #this string will serve as the upper and lower thirds of the row
		rowmeat = (board.index(row) + 1).to_s + " "
		row.each do |tile|
			rowbread += tile.bread #adds the top/bottom three characters of the tile
			rowmeat += tile.meat #adds the middle three characters of the tile
		end
		puts rowbread + legend.slice!(1).to_s
		puts rowmeat + legend.slice!(1).to_s
		puts rowbread + legend.slice!(1).to_s
	end
	DEST_EMPTY_OR_ENEMY = Proc.new do |move|
		next true if move.destination == "castle"
		next false unless move.simlevel.tiles.include?(move.destination)
		next true unless move.destination.occupied_piece
		next false if move.destination.occupied_piece.team == move.piece.team
		next false if move.destination == move.departure
		true
	end
	def generate_valid_moves #returns a list of every possible valid move for a given turn from an array of tiles
		self.movelist = [] #this is a list of all valid moves for the given state of the board, will be returned at the end
		mover_pieces = self.active_pieces.select {|piece|
			piece.team == self.moving_team
		}
		mover_pieces.each {|piece| piece_valid_moves(piece)}
		self.movelist.select!(&DEST_EMPTY_OR_ENEMY)
		raise unless movelist.is_a?(Array)
		self.movelist
		#note: we do not determine at this stage whether these moves will put the friendly king in check, because that would be absolute hell in terms of both memory efficieny and our ability to read the code.
	end
	def piece_valid_moves(piece)
		nonself_moves_before = self.movelist.select {|move| move.piece != piece}
		destinations = piece.criteria
		destinations.each do |destination|
			unless destination.occupied_piece && destination.occupied_piece.team == piece.team
				move = Move.new(self.game, piece.tile, destination)
				raise if move.taken && move.taken.team == move.piece.team
				self.movelist.push(move)
			end
		end
		nonself_moves_after = self.movelist.select {|move| move.piece != piece}
		nonself_moves_edit_err_message(nonself_moves_before, nonself_moves_after)
	end
	def nonself_moves_edit_err_message(nonself_moves_before, nonself_moves_after)
		unless nonself_moves_before == nonself_moves_after
			puts "piece.tile = #{piece.tile.name}, #{piece.depth.to_s} piece.name = #{piece.name} #{piece.simlevel.object_id}"
			puts "added:"
			(nonself_moves_after - nonself_moves_before).each do |move|
				puts "#{move.piece.name} #{move.piece.depth.to_s} #{move.departure.name} #{move.destination.name}  #{move.simlevel.object_id}"
			end
			puts "removed:"
			(nonself_moves_before- nonself_moves_after).each do |move|
				puts "#{move.piece.name} #{move.departure.name} #{move.destination.name}, #{move.simlevel.object_id}"
			end
			raise "#{piece.name} is adding or deleting other pieces' moves"
			# each piece's criteria should be deleting any invalid moves that move
			# that piece, and, in the case of a rook, adding an option to castle if
			# applicable. If moves that move other pieces get added or removed,
			# something isn't working correctly.
		end
	end
end


class Simlevel < Boardstate #used for check_detect and checkmate_detect
	def initialize(game, superboard = [], superdepth) #the "super" prefix means that something is from the level above the one being created
		@game = game
		@depth = (superdepth - 1) #how many levels of simulation deep are we?
		@board = []
		@pieces = []
		@game.simlevels[(depth * (-1))] = self
		$obj_id = self.object_id
		superboard.each do |superrow|
			row = []
			superrow.each do |supertile|
				simtile = supertile.simulate
				simtile.occupied_piece.name if simtile.occupied_piece
				supertile.occupied_piece.name if supertile.occupied_piece
				row.push(simtile)
			end
			@board.push(row)
		end
		@tiles = board.flatten
		@moving_team = self.wake_up.moving_team
		@white_king = @pieces.find {|piece| piece.title == "white king"}
		@black_king = @pieces.find {|piece| piece.title == "black king"}
		@turn_counter = game.boardstate.turn_counter
		@fifty_move_counter = game.simlevels[superdepth].fifty_move_counter
		@game_over = false
		@movelist = []
	end
	def go_deeper
		sublevel = game.simlevels.find {|level| level.depth == (@depth - 1)}
		return sublevel
	end
	def wake_up #think "Inception"
		superlevel = game.simlevels.find {|level| level.depth == (@depth + 1)}
		return superlevel
	end
	def simulate
		super
	end
	def friendly_king
		super
	end
	def enemy_king
		super
	end
end

OPENING_MOVES = [ #for debugging
	["A2", "A3"], ["A2, A4"], ["B2", "B3"], ["B2", "B4"], ["C2", "C3"],
	["C2", "C4"], ["D2", "D3"], ["D2", "D4"], ["E2", "E3"], ["E2", "E4"],
	["F2", "F3"], ["F2", "F4"], ["G2", "G3"], ["G2", " G4"], ["H2", "H3"],
	["H2", "H4"], ["B1", "A3"], ["B1", "C3"], ["G1", "F3"], ["G1", "H3"]
]

def valid_opening?(opening) #for debugging
	formatted_opening = [opening.departure.coordinates.name, opening.destination.coordinates.name]
	return OPENING_MOVES.include?(formatted_opening)
end

class Path # used to find the possible moves of a rook, bishop, or queen
	attr_accessor :x_step, :y_step, :piece, :name, :tiles, :x_ori, :y_ori
	def initialize(piece, name)
		@name = name
		@x_ori = self.set_x_orientation # in which direction, if any, do we move
		@y_ori = self.set_y_orientation # along the x or y axis during each step?
		@name = name
		@piece = piece
		@tiles = []
		@x_step = @piece.tile.coordinates.x_axis # what is the x- or y-coordinate
		@y_step = @piece.tile.coordinates.y_axis # of our current step?
		self.fill_path
	end
	def set_y_orientation
		if (self.name.upcase == "N") || (self.name.chop.upcase == "N")
			return 1
		elsif (self.name.upcase =="S") || (self.name.chop.upcase == "S")
			return -1
		else
			return 0
		end
	end
	def set_x_orientation
		if (self.name.upcase == "E") || (self.name.reverse.chop.upcase == "E")
			return 1
		elsif (self.name.upcase == "W") || (self.name.reverse.chop.upcase == "W")
			return -1
		else
			return 0
		end
	end
	def take_step # in order to find our path, we keep taking steps in a given
		self.x_step += self.x_ori # direction (up, down, left, right, diagonal)
		self.y_step += self.y_ori # until we run into another piece or reach the
		tiles = self.piece.simlevel.tiles
		step = tiles.find {|tile| tile.coordinates.x_axis == self.x_step &&
			tile.coordinates.y_axis == self.y_step
		}
	end
	def fill_path
		loop do
			step = self.take_step # end of the board
			if step == nil # if we have reached the end of the board
				break # we cannot take any more steps
			elsif step.occupied_piece == nil # if the tile is unoccupied it is added
				self.tiles.push(step) # to the path and we can take another step
			elsif step.occupied_piece.team == self.piece.team # if the tile is occupied
				break # by a friendly piece then we cannot take any more steps
			else # the only remaining possibility is that the tile is occupied by an
				self.tiles.push(step) # enemy piece, which means that we can make this
				break # step but cannot move beyond it
			end
		end
	end
end

class CastlePath # note: not a subclass of Path
	attr_accessor :rook, :tiles, :king_tiles, :king, :rook_tiles,
	:rook_dest, :king_dest
	def initialize(rook)
		@rook = rook
		@king = rook.team.kings[rook.depth.abs]
		@tiles = @rook.simlevel.tiles
		@rook_tiles = []
		@king_tiles = []
		self.find_rook_path
		self.find_rook_path
		@rook_dest = @rook_tiles.last if @rook_tiles
		@king_dest = @king_tiles.last if @king_tiles
	end
	def find_rook_path
		rook_path_hash = {
			"A1" => ["B1", "C1" "D1"], "A8" => ["B8", "C8" "D8"],
			"H1" => ["G1", "F1"], "H8" => ["G8", "F8"]
		}
		tiles = self.rook.simlevel.tiles
		rook_path_hash[self.rook.tile.coordinates.name.capitalize].each do |coor|
			tile = tiles.find {|tile| tile.coordinates.name == coor}
			self.rook_tiles.push(tile) if tile
		end
	end
	def find_king_path
		king_path_hash = {
			"A1" => ["E1", "D1" "C1"], "A8" => ["E8", "D8" "C8"],
			"H1" => ["E1", "F1", "G1"], "H8" => ["E8", "F8", "G1"]
		}
		king_path_hash[self.rook.tile.name.capitalize].each do |coor|
			tile = tiles.find {|tile| tile.coordinates.name == coor}
			self.king_tiles.push(tile)
		end
	end
	def clear?
		if self.rook_tiles.is_a?(Array) && !self.rook_tiles.empty?
			!(self.rook_tiles.any? {|tile| tile.occupied_piece})
		end
	end
	def safe?
		self.king_tiles.any? {|tile|
			Move.new(self.rook.game, king.tile, tile).ally_check
		}
	end
end

class Piece
	extend UserPrompt
	attr_accessor :promoted_from, :coordinates, :serial, :depth, :game, :moved, :color
	class << self; attr_accessor :black_symbol, :white_symbol end
	@white_symbol = "?"
	@black_symbol = "?"
	def initialize(color, tilename, serial, game, depth = 0)
		@depth = depth
		@color = color
		@game = game
		@coordinates = $coordinates.find {|coor| coor.name == tilename.upcase}
		self.clear_tile if @game && @game.simlevels
		@serial = serial
		@moved = false
		self.simlevel.pieces.push(self)
	end
	def clear_tile
		current_occupants = self.simlevel.pieces.select {|piece|
			piece.coordinates == self.coordinates && !(piece.equal?(self))
		}
		current_occupants.each do |piece|
			piece.coordinates = nil
		end
	end
	def title
		color + " " + self.class.to_s.downcase
	end
	def name
		color + "_" + self.class.to_s + "_" + serial.to_s
	end
	def symbol_color
		symb_color = self.color
		if $neg_display && symb_color == "black"
			symb_color == "white"
		elsif $neg_display && symb_color == "white"
			symb_color == "black"
		end
		symb_color
	end
	def symbol(color = self.symbol_color)
		if color == "white"
			return self.class.white_symbol
		else
			return self.class.black_symbol
		end
	end
	def simlevel
		self.game.simlevels[self.depth.abs]
	end
	def team
		if color == "black"
			return self.game.black_team
		else
			return self.game.white_team
		end
	end
	def tile
		self.simlevel.tiles.find {
			|tile| tile.coordinates == self.coordinates
		}
	end
	def simulate
		piece_sim = self.class.new(self.color, self.tile.coordinates.name, self.serial, self.game, self.depth - 1)
		piece_sim.moved = self.moved
		piece_sim.promoted_from = self.promoted_from
		piece_sim
	end
	def plus_path #all the possible moves of a rook
		north_path = Path.new(self, "N")
		east_path = Path.new(self, "E")
		south_path = Path.new(self, "S")
		west_path = Path.new(self, "W")
		north_path.tiles + east_path.tiles + south_path.tiles + west_path.tiles
	end
	def x_path # all the possible moves of a bishop
		nw_path = Path.new(self, "NW")
		ne_path = Path.new(self, "NE")
		se_path = Path.new(self, "SE")
		sw_path = Path.new(self, "SW")
		nw_path.tiles + ne_path.tiles + se_path.tiles + sw_path.tiles
	end
	def move_to(dest) # can accept a string, tile, or coordinates
		if dest.is_a?(String)
			dest = simlevel.tiles.find {|tile| tile.coordinates.name == dest}
		elsif dest.is_a?(Coordinates)
			dest = simlevel.tiles.find {|tile| tile.coordinates == dest}
		end
		raise "Not a valid destination" unless dest.is_a?(Tile)
		dest.occupied_piece.coordinates = nil if dest.occupied_piece
		self.coordinates = dest.coordinates
		self.moved = true
	end
end


def in_between(a, b)
	in_between_list = []
	if a > b
		for x in ((b + 1)...a)
			in_between_list.push(x)
		end
	elsif b > a
		for x in ((a + 1)...b)
			in_between_list.push(x)
		end
	end
	return in_between_list
end

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

class Knight < Piece
	@white_symbol = "♞"
	@black_symbol = "♘"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
	end
	def criteria
		valid_destinations = []
		possible_destinations = self.simlevel.tiles.dup
		possible_destinations.each do |dest|
			x_difference = (dest.coordinates.x_axis - self.tile.coordinates.x_axis).abs
			y_difference = (dest.coordinates.y_axis - self.tile.coordinates.y_axis).abs
			if (x_difference == 1 && y_difference == 2) || (x_difference == 2 && y_difference == 1)
				valid_destinations.push(dest)
			end
		end
		return valid_destinations
	end
end

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

class King < Piece
	@white_symbol = "♚"
	@black_symbol = "♔"
	def initialize(color, tilename, serial, game, depth = 0)
		super(color, tilename, serial, game, depth)
	end
	def criteria
		valid_destinations = []
		candidate_destinations = self.simlevel.tiles.dup
		candidate_destinations.each do |dest|
			x_diff = (dest.coordinates.x_axis - self.tile.coordinates.x_axis).abs
			y_diff = (dest.coordinates.y_axis - self.coordinates.y_axis).abs
			x_one_or_zero = ((x_diff == 1) || (x_diff == 0))
			y_one_or_zero = ((y_diff == 1) || (y_diff == 0))
			if x_one_or_zero && y_one_or_zero && dest != self.tile
				valid_destinations.push(dest)
			end
		end
		return valid_destinations
	end
end

class Queen < Piece
	@white_symbol = "♛"
	@black_symbol = "♕"
	def initialize(team, tilename, serial, game, depth = 0)
		super(team, tilename, serial, game, depth)
	end
	def criteria
		(self.plus_path + self.x_path)
	end
end

class Pawn < Piece
	@white_symbol = "♟"
	@black_symbol = "♙"
	attr_accessor :orientation
	def initialize(color, tilename, serial, game, depth = 0)
		super(color, tilename, serial, game, depth)
		@orientation = 1 #which way is this pawn moving?
		@orientation = (-1) if color == "black"
	end
	def one_tile_ahead(destinations)
		dest = self.simlevel.tiles.find {|tile|
			tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
			tile.coordinates.x_axis == self.coordinates.x_axis
		}
		unless !dest || dest.occupied_piece
			destinations.push(dest)
			return dest
		end
	end
	def two_tiles_ahead(destinations)
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + 2*self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis
		}
		destinations.push(dest) unless !dest || dest.occupied_piece || self.moved
	end
	def right_diagonal(destinations) #the tile ahead and to the right that the
		# pawn can move to if it's occupied by an enemy piece
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis + 1
		}
		taken = dest.occupied_piece if dest
		destinations.push(dest) unless !dest || !taken || taken.team == self.team
		dest
	end
	def left_diagonal(destinations)
		dest = self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis + self.orientation &&
		tile.coordinates.x_axis == self.coordinates.x_axis - 1
		}
		taken = dest.occupied_piece if !!dest
		destinations.push(dest) unless !dest || !taken || taken.team == self.team
		dest
	end
	def right_adjacent
		self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis &&
		tile.coordinates.x_axis == self.coordinates.x_axis + 1
	}
	end
	def left_adjacent
		self.simlevel.tiles.find {|tile|
		tile.coordinates.y_axis == self.coordinates.y_axis &&
		tile.coordinates.x_axis == self.coordinates.x_axis - 1
	}
	end
	def right_passant(r_diag)
		#the tile two squares ahead and one square to the right that an enemy pawn would need to have moved from in order to give this piece the opportunity to make an en_passant move
		taken = self.right_adjacent.occupied_piece if !!self.right_adjacent
		last_move = self.game.history.last
		y_coor = self.coordinates.y_axis + 2*self.orientation
		x_coor = self.coordinates.x_axis + 1
		passant = self.simlevel.tiles.find { |tile|
			tile.coordinates.y_axis == y_coor && tile.coordinates.x_axis == x_coor }
		if (!!taken && taken.team != self.team && taken.is_a?(Pawn) &&
			!!last_move && last_move.piece == taken &&
			last_move.departure == passant &&
			last_move.destination == self.right_adjacent)
			return r_diag
		else
			return nil
		end
	end
	def left_passant(l_diag)
		taken = self.left_adjacent.occupied_piece if !!self.left_adjacent
		last_move = self.game.history.last
		y_coor = self.coordinates.y_axis + 2*self.orientation
		x_coor = self.coordinates.x_axis - 1
		passant = self.simlevel.tiles.find { |tile|
			tile.coordinates.y_axis == y_coor && tile.coordinates.x_axis == x_coor }
		if (!!taken && taken.team != self.team && taken.is_a?(Pawn) &&
			!!last_move && last_move.piece == taken &&
			last_move.departure == passant &&
			last_move.destination == self.left_adjacent)
			return l_diag
		else
			return nil
		end
	end
	def add_passant_moves(r_pass, l_pass)
		if r_pass
			en_passant_move = Move.new(self.game, self.tile, r_pass)
			en_passant_move.taken = self.right_adjacent.occupied_piece
			self.simlevel.movelist.push(en_passant_move)
		elsif l_pass # there can only be one en passant move, because the
			# destination of an en passant move is relative to the last move
			en_passant_move = Move.new(self.game, self.tile, l_pass)
			en_passant_move.taken = self.left_adjacent.occupied_piece
			self.simlevel.movelist.push(en_passant_move)
		end
	end
	def criteria
		destinations = []
		self.two_tiles_ahead(destinations) if self.one_tile_ahead(destinations)
		r_diag = self.right_diagonal(destinations)
		l_diag = self.left_diagonal(destinations)
		#the next set of if statements deals with en_passant
		r_pass = self.right_passant(r_diag)
		l_pass = self.left_passant(l_diag)
		self.add_passant_moves(r_pass, l_pass)
		return destinations
	end
	def promotion_conditions(move)
		if [1, 8].include?(move.destination.coordinates.y_axis) &&
			move.team.player.name == "AI"
			self.promote("random", move)
		elsif [1, 8].include?(move.destination.coordinates.y_axis)
			self.promotion_prompt(move)
		end
	end
	PROMO_KLASSES = [Queen, Knight, Bishop, Rook]
	PROMO_LAM = lambda do |response, klasses|
		promo_klass = klasses.find {|klass| klass.to_s == response.capitalize}
		if response.downcase! == "random"
			return {return: klasses.sample}
		elsif promo_klass
			return {return: promo_klass}
		elsif (response == "king") || (response == "pawn")
			return {error: "Sorry, you can't promote to a #{response}."}
		else
			return nil
		end
	end
	def promotion_prompt(move)
		promo_klass = Pawn.prompt_until_valid("What should I promote your pawn to?",
		PROMO_LAM, nil, PROMO_KLASSES)
		self.promote(promo_klass, move)
	end
	def promote(promo_klass, move)
		klassmates = self.simlevel.pieces.select {|piece|
			piece.is_a?(promo_klass) && piece.team == self.team
		}
		serial = klassmates.count + 1
		replacement = promo_klass.new(self.team, self.tile.name,
		serial, self.game, self.depth)
		self.coordinates = nil
		replacement.moved = true
		replacement.promoted_from = self.name
		replacement
	end
end

class Tile
	attr_accessor :coordinates, :depth, :game
	def initialize(x, y, depth = 0, game = nil)
		alphanum = Coordinates.num_to_alphanum(x, y)
		@coordinates =  $coordinates.find {|coordinate| coordinate.name == alphanum}
		@coordinates = Coordinates.new(alphanum) unless @coordinates
		@depth = depth
		@game = game
	end
	def boardstate
		level = self.game.simlevels.find {|level| level.depth == self.depth}
		self.game.simlevels.find {|level| level.depth == self.depth}
	end
	def occupied_piece
		if self.game
			self.boardstate.pieces.find {|piece| piece.coordinates == self.coordinates}
		else
			return nil
		end
	end
	def name
		self.coordinates.name
	end
	def color
		# helps specify the color of a tile based on the x and y coordinates
		total = self.coordinates.x_axis + self.coordinates.y_axis
		# If the sum of the x and y coordinates is evem, then it should be black.
		# Otherwise it should be white.
		is_even = (total % 2).zero?
		if is_even == true
			return "white"
		else
			return "black"
		end
	end
	def color_square
		if ((self.color == "black") && $neg_display) || ((self.color == "white") && !$neg_display)
			return "■" #used to help color the tile appropriately when displayed
		else
			return "□"
		end
	end
	def simulate
		simtile = Tile.new((self.coordinates.x_axis), (self.coordinates.y_axis), (self.depth - 1), self.game)
		piece_sim = self.occupied_piece.simulate if self.occupied_piece
		simtile
	end
	def center_symbol
		if self.occupied_piece
			return self.occupied_piece.symbol
		else
			return self.color_square
		end
	end
	def meat
		if self.color_square.nil? || self.center_symbol.nil?
			puts "piece = #{self.occupied_piece.name} color_square = #{self.color_square.to_s} center_symbol = #{self.center_symbol.to_s}"
		end
		#this string will serve as both the upper and lower third of this tile when
		#displayed on the board when we call the board_display function
		(self.color_square + self.center_symbol + self.color_square)
	end
	def bread
		(self.color_square * 3)
	end
end

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

class Move
	attr_accessor :departure, :piece, :destination, :taken, :team, :enemy, :turn,
	:extras, :game_end, :snapshot, :previous_turn, :following_turn, :game,
	:ally_check_cache, :enemy_check_cache, :first_move, :simlevel
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
		self.game.history.find_index(found_move) + 1
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
			[1, 8].include?(self.destination.coordinates.y_axis)
			return self.promotion_check_detect
		elsif self.enemy_check_cache.nil?
			return self.enemy_check_detect
		else
			return self.enemy_check_cache
		end
	end
	def ally_check_detect
		outcome = self.simulate_outcome
		outcome.generate_valid_moves
		possible_moves = outcome.movelist
		check_moves = possible_moves.select {|move| move.taken.is_a?(King)}
		if check_moves.empty?
			self.ally_check_cache = false
		else
			self.ally_check_cache = check_moves
		end
		self.ally_check_cache
	end
	def enemy_check_detect(outcome = self.simulate_outcome)
		outcome.moving_team = outcome.moving_team.opposite #we proceed as though the moving team gets another free turn
		possible_moves = outcome.generate_valid_moves
		check_moves = possible_moves.select {|move| move.taken.is_a?(King)}
		if check_moves.empty?
			return self.enemy_check_cache = false
		else
			return self.enemy_check_cache = check_moves
		end
	end
	def promotion_check_detect
		check_moves = [Queen, Knight].inject([]) do |ch_moves, klass| # there are no situations where promoting to a rook or bishop would result in check but promoting to a queen wouldn't.
			promotion_outcome = self.simulate_outcome
			to_be_promoted = promotion_outcome.pieces.find do |piece|
				piece.name == self.piece.name
			end
			to_be_promoted.promote(klass, self)
			ecd = self.enemy_check_detect(promotion_outcome)
			ch_moves.push(ecd) if ecd
			ch_moves
		end
		self.enemy_check_cache = (check_moves.empty? ? false : check_moves)
	end
	def simulate_outcome
		simstate = (self.game.simlevels.find {|level| (level.depth == self.piece.depth)}).simulate
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
		moved_piece = simstate.pieces.find {|piece| piece.name == self.piece.name}
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
		puts self.destination.occupied_piece
		self.game.history.push(self)
		self.simlevel.turn_counter += 1
		self.piece.moved = true
		self.simlevel.moving_team = self.simlevel.moving_team.opposite
		self.snapshot = Snapshot.new(self.simlevel)
		self.mate_detect
		self.game.boardstate.display
		self.three_move_rule
		self.fifty_move_rule
		if self.enemy_check
			puts "#{self.enemy.color}'s king is in check from:"
			enemy_check.each {|m| puts m.summary}
		end
	end
	def mate_detect
		self.simlevel.generate_valid_moves
		valid_move = self.simlevel.movelist.find {|found_move| !found_move.ally_check}
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
end

=begin

The board is a two-dimensional array of all tiles that
is only used in the board_display function. The tiles array
is a flattened version of the board, which is easier to look
up individual tiles from using the .find method. Only the main
boardstate has a board as an attribute, simlevels don't need
them as they are never displayed. Tile arrays exists as an
attribute of both the main boardstate and all simlevels.

=end

def test_protocol(movelist) #debugging tool
	movelist.each do |move| #delete later
		if move.destination == "castle"
			puts move.piece.name + " " + move.departure.coordinates.name + " castle"
		else
			puts move.piece.name + " " + move.departure.coordinates.name + " to " + move.destination.coordinates.name
		end
	end
end



=begin
To explain how the display works: each tile is a 3x3 arrangement of unicode
characters, the middle of which is the piece icon:

■■■
■♖■
■■■

It, uh, looks a lot better in command prompt, just trust me.
Anyway, the top three characters are called the "bread", as are the bottom
three. The "meat" is the middle three (think of a sandwich). So:

bread
meat
bread

When we print out the display, we combine all the breads of the tiles in a
given row to make onelong string, then do the same for the meat. Then, for each
row we print out bread, then meat on the next line, then bread again on the
next, like so:

A1bread B1bread C1bread D1bread E1bread F1bread G1bread H1bread
A1meat  B1meat  C1meat  D1meat  E1meat  F1meat  G1meat  H1meat
A1bread B1bread C1bread D1bread E1bread F1bread G1bread H1bread

We do this for each row, then also add axes and legends where appropriate.

=end

if $needs_testing == true # this step is ony for debugging
	$test_protocol
end

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

MainMenu.new
