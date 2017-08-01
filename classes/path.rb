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
