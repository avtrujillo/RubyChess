# used to find the possible moves of a rook, bishop, or queen
# each instance of Path only covers one direction for one piece on a given turn
class Path
	attr_accessor :x_step, :y_step, :piece, :name, :tiles, :x_ori, :y_ori
	def initialize(piece, name)
		raise 'invalid name length' if name.length > 2 || name.length.zero?
		@name = name # NE, NW, SE, or SW (That is, 'northeast' etc.)
		@x_ori = set_x_orientation # in which direction, if any, do we move
		@y_ori = set_y_orientation # => along the x or y axis during each step?
		@piece = piece
		@all_tiles = @piece.simlevel.tiles
		@tiles = []
		@x_step = @piece.tile.coordinates.x_axis # what is the x- or y-coordinate
		@y_step = @piece.tile.coordinates.y_axis # => of our current step?
		self.fill_path
	end
	def set_y_orientation
		case @name.chars.first.upcase
		when 'N'
			return 1
		when 'S'
			return -1
		when 'E' || 'W'
			return 0
		else
			raise 'first character of path name is invalid'
		end
	end
	def set_x_orientation
		case @name.chars.last.upcase
		when 'E'
			return 1
		when 'W'
			return -1
		when 'N' || 'S'
			return 0
		else
			raise 'last character of path name is invalid'
		end
	end
	def take_step # in order to find our path, we keep taking steps in a given
		self.x_step += self.x_ori # => direction (up, down, left, right, diagonal)
		self.y_step += self.y_ori # => until we reach the end of the board
		@all_tiles.find do |tile|
			tile.coordinates.x_axis == self.x_step &&
			tile.coordinates.y_axis == self.y_step
		end
	end

	def fill_path
		# finds the path of tiles from @piece to the end of the board in a given
		# => direction, then passes that on to crop_path and returns it
		path_tiles = []
		loop do
			step = take_step
			unless step.nil?
				tiles << step
			else
				return crop_path(path_tiles)
			end
		end
	end

# Having found the path of tiles from @piece to the end of the board in a given
# => direction, we now crop it so that @ piece cannot land on a friendly piece
# =>  or move past another piece of either color
	def crop_path(path_tiles) # path_tiles was already sorted by distance from
		path_tiles.each do |tile| # => @piece when it was created in fill_path
			if tile.occupied_piece.nil?
				@tiles << tile
			elsif tile.occupied_piece.team != @piece.team
				@tiles << tile # @piece can take an enemy piece but cannot move past it
    		return @tiles
			elsif tile.occupied_piece.team == @piece.team
				return @tiles # @piece can neither take nor move past a friendly piece
			end
   	end
	end
end
