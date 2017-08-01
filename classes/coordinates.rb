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
