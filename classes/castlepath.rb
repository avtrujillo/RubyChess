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
