# note: not a subclass of Path
class CastlePath
	attr_reader :rook, :tiles, :king_tiles, :king, :rook_tiles,
	:rook_dest, :king_dest
	def initialize(rook)
		@rook = rook
		@king = rook.team.kings[rook.depth.abs]
		@tiles = @rook.simlevel.tiles
		@rook_tiles = []
		@king_tiles = []
		find_king_path
		find_rook_path
		@rook_dest = @rook_tiles.last
		@king_dest = @king_tiles.last
	end

	ROOK_PATH_HASH = {
		'A1' => ['B1', 'C1', 'D1'], 'A8' => ['B8', 'C8', 'D8'],
		'H1' => ['G1', 'F1'], 'H8' => ['G8', 'F8']
	}

	def find_rook_path
		tiles = @rook.simlevel.tiles
		ROOK_PATH_HASH[@rook.tile.coordinates.name.capitalize].each do |coor|
			tile = @tiles.find {|t| t.coordinates.name == coor}
			@rook_tiles << tile if tile
		end
	end

	KING_PATH_HASH = {
		'A1' => ['E1', 'D1' 'C1'], 'A8' => ['E8', 'D8' 'C8'],
		'H1' => ['E1', 'F1', 'G1'], 'H8' => ['E8', 'F8', 'G1']
	}

	def find_king_path
		KING_PATH_HASH[self.rook.tile.name.capitalize].each do |coor|
			tile = @tiles.find {|t| t.coordinates.name == coor}
			@king_tiles << tile
		end
	end

	def clear?
		!@king_tiles.empty? &&
		@king_tiles.none? {|tile| tile.occupied_piece} &&
		!@rook_tiles.empty? &&
		@rook_tiles.none? {|tile| tile.occupied_piece}
	end

	def safe?
		@king_tiles.none? do |tile|
			Move.new(@.rook.game, @king.tile, tile).ally_check
		end
	end

end
