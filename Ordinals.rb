module Ordinals

  class ThreeDigits
    attr_accessor :final
    attr_reader :period_name, :houndreds, :tens, :ones, :period, :period_string,
    :full_period_int

    def initialize(period_index, ones = 0, tens = 0, houndreds = 0)
      @houndreds_int = houndreds
      @tens_int = tens
      @ones_int = ones
      @last_two_digit_int = (@tens_int * 10) + @ones_int
      @full_period_int = (@houndreds_int * 100) + @last_two_digit_int
      @period_index = period_index
      @period_name = PERIOD_NAMES[@period_index]
    end
    def final_period(final_found)
      @final = ((final_found || @full_period_int.zero?) ? false : true)
    end
    public
    def set_string
      @period_string = self.name_houndreds + self.name_last_two_digits
    end

    private
    def self.int_from_ordinal_string(str)
      (negative, str) = self.is_string_negative(str)
      puts str.dump
      int = 0
      loop do
        test_string = ordinal_string_from_int(int)
        puts test_string.dump
        break if test_string == str
        raise "not found or out of range" if int == (999 * (10 ** 100))
        int += 1
      end
      int *= (-1) if negative
      int
    end
    def self.is_string_negative(str)
      negative = false
      if str[0..5].downcase == "minus "
        negative = true
        str = str[6..-1]
      elsif str[0..8].downcase == "negative "
        str = str[9..-1]
        negative = true
      end
      return [negative, str]
    end
    def self.ordinal_string_from_int(int)
      if int.negative?
        return "negative " + self.ordinal_string_from_int(int * (-1))
      end
      digit_array = ThreeDigits.digits_from_int(int)
      three_digit_groups = ThreeDigits.group_digits_into_threes(digit_array)
      periods = ThreeDigits.make_periods(three_digit_groups)
      ThreeDigits.find_final(periods)
      ThreeDigits.combine_period_strings(periods)
    end
    def self.digits_from_int(int)
      char_array = int.to_s.chars
      digit_array = []
      char_array.each do |char|
        digit_array << char.to_i
      end
      digit_array
    end
    def self.group_digits_into_threes(digit_array)
      periods = []
      current_period = []
      digit_array.reverse_each do |digit|
        current_period.unshift(digit)
        if current_period.count == 3
          periods.unshift(current_period)
          current_period = []
        end
      end
      periods.unshift(current_period)
      periods
    end
    def self.make_periods(periods)
      periods.reverse!.each_with_index do |period, index|
        period.unshift(0) until period.count == 3
        ones = (period[2] || 0)
        tens = (period[1] || 0)
        houndreds = (period[0] || 0 )
        periods[index] = ThreeDigits.new(index, ones, tens, houndreds)
      end
      periods
    end
    def self.find_final(periods)
      final_found = false
      periods.each do |period|
        final_found = true if period.final_period(final_found)
      end
      periods.first.final = true unless final_found
    end
    def self.combine_period_strings(periods)
      full_string = ""
      periods.reverse!.each do |period|
        period.set_string
        full_string += period.period_string
      end
      full_string
    end
    protected
    def final_int
      if @final_int
        return @final_int
      elsif @ones_int.nonzero?
        return @final_int = "ones"
      elsif @tens_int.nonzero?
        return @final_int = "tens"
      elsif @houndreds_int.nonzero?
        return @final_int = "houndreds"
      else
        return "none"
      end
    end
    def name_houndreds
      if @houndreds_int.zero?
        @houndred_string = ""
      elsif @final && self.final_int == "houndreds" && @period_index.zero?
        @houndred_string = ZERO_THRU_19_WORDS[@houndreds_int] + " houndredth"
      elsif @final && self.final_int == "houndreds"
        @houndred_string = ZERO_THRU_19_WORDS[@houndreds_int]
        @houndred_string += " #{PERIOD_NAMES[@period_index]}th"
      elsif self.final_int == "houndreds"
        @houndred_string = ZERO_THRU_19_WORDS[@houndreds_int]
        @houndred_string += " #{PERIOD_NAMES[@period_index]} "
      else
        @houndred_string = "#{ZERO_THRU_19_WORDS[@houndreds_int]} houndred "
      end
    end
    def name_last_two_digits
      if @final && @full_period_int.zero?
        @last_two_digit_string = "zeroth"
      elsif @last_two_digit_int.zero?
        @last_two_digit_string = ""
      elsif @final && @period_index.zero? && @last_two_digit_int < 20
        @last_two_digit_string = ZEROTH_THRU_19TH_ORDINALS[@last_two_digit_int]
      elsif @final && @last_two_digit_int < 20
        @last_two_digit_string = ZERO_THRU_19_WORDS[@last_two_digit_int]
        @last_two_digit_string += " #{PERIOD_NAMES[@period_index]}th"
      elsif @final && @ones_int.zero?
        @last_two_digit_string = TEN_MULTIPLE_ORDINALS[@tens_int]
      elsif @final && @ones_int.nonzero?
        @last_two_digit_string = TEN_MULTIPLE_WORDS[@tens_int] + "-"
        @last_two_digit_string += ZEROTH_THRU_19TH_ORDINALS[@ones_int]
      elsif @last_two_digit_int < 20
        @last_two_digit_string = ZERO_THRU_19_WORDS[@last_two_digit_int]
        @last_two_digit_string += " #{PERIOD_NAMES[@period_index]} "
      elsif @ones_int.zero?
        @last_two_digit_string = TEN_MULTIPLE_WORDS[@tens_int]
        @last_two_digit_string += " #{PERIOD_NAMES[@period_index]} "
      else
        @last_two_digit_string = TEN_MULTIPLE_WORDS[@tens_int] + "-"
        @last_two_digit_string += ZERO_THRU_19_WORDS[@ones_int]
        @last_two_digit_string += " #{PERIOD_NAMES[@period_index]} "
      end
    end
    PERIOD_NAMES = [
      "", "thousand", "million", "billion", "trillion", "quadrillion",
      "pentillion", "hexillion", "heptillion", "octillion", "nonillion",
      "decillion", "undecillion", "duodecillion", "tredecillion",
      "quattuordecillion", "quindecillion", "sexdecillion", "septendecillion",
      "octodecillion", "novemdecillion", "vigintillion", "unvigintillion",
      "duovigintillion", "trevigintillion", "quattuorvigintillion",
      "quinvigintillion", "sexvigintillion", "septenvigintillion",
      "octovigintillion", "novemvigintillion", "trigintillion",
      "untrigintillion", "duotrigintillion", "googol"
    ]
    ZEROTH_THRU_19TH_ORDINALS = [
      "zeroth", "first", "second", "third", "fourth", "fifth", "sixth",
      "seventh", "eighth", "ninth", "tenth", "eleventh", "twelfth",
      "thirteenth", "fouteenth", "fifteenth", "sixteenth", "seventeenth",
      "eigteenth", "nineteenth"
    ]
    ZERO_THRU_19_WORDS = [
      "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
      "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
      "sixteen", "seventeen", "eighteen", "nineteen"
    ]
    TEN_MULTIPLE_WORDS = [
      "", "ten", "twenty", "thirty", "fourty", "fifty", "sixty", "seventy",
      "eighty", "nintey"
    ]
    private
    def self.ten_multiple_ordinals
      tmo = []
      TEN_MULTIPLE_WORDS.each do |word|
        word = word.split("y")[0]
        word += "ieth" if word
        tmo << word
      end
      tmo[0] = "zeroth"
      tmo[1] = "tenth"
      tmo[9] = "nintieth"
      tmo
    end
    TEN_MULTIPLE_ORDINALS = ThreeDigits.ten_multiple_ordinals
  end
end
