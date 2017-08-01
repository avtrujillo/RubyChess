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
			raise if self.coordinates.nil? || self.nil?
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
		raise if self.coordinates.nil? || self.nil?
		self.promote(promo_klass, move)
	end
	def promote(promo_klass, move)
		klassmates = self.simlevel.pieces.select {|piece|
			piece.is_a?(promo_klass) && piece.team == self.team
		}
		promoted = self.simlevel.pieces.select {|piece|
			piece.promoted_from == self.name
		}
		#raise if promoted
		serial = klassmates.count + 1
		#raise if self.coordinates.nil? || self.nil?
		replacement = promoted.first || promo_klass.new(self.team.color, self.coordinates.name,
		serial, self.game, self.depth)
		self.coordinates = nil
		replacement.moved = true
		replacement.promoted_from = self.name
		replacement
	end
end
