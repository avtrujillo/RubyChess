class Simlevel < Boardstate #used for check_detect and checkmate_detect
	def initialize(game, superboard = [], superdepth) #the "super" prefix means that something is from the level above the one being created
		@game = game
		@depth = (superdepth - 1) #how many levels of simulation deep are we?
		@board = []
		@pieces = []
		@game.simlevels[(depth * (-1))] = self
		$obj_id = self.object_id # delete later
		superboard.each do |superrow|
			row = []
			superrow.each do |supertile|
				simtile = supertile.simulate(self)
				simtile.sim_id = self.sim_id
				row.push(simtile)
			end
			@board.push(row)
		end
		@tiles = board.flatten
		@tiles.each {|tile| @pieces.push(tile.occupied_piece) if tile.occupied_piece}
	#	byebug if @pieces.empty?
		@moving_team = self.wake_up.moving_team
		@white_king = @pieces.find {|piece| piece.title == "white king"}
		@black_king = @pieces.find {|piece| piece.title == "black king"}
		@turn_counter = game.boardstate.turn_counter
		@fifty_move_counter = game.simlevels[superdepth].fifty_move_counter
		@game_over = false
		@movelist = []
		self.set_sim_id
		@pieces.each {|piece| piece.sim_id = self.sim_id}
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
