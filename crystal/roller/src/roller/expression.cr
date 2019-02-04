module Roller
  class Expression
    def initialize(@raw_expression : String = "1d20")
      @iterations = 1
      @modifier = 0
      @casts = 1
      @die = 20

      @args = [] of String
      @args = @raw_expression.downcase.gsub(/ +/, "").gsub(/([\-\+]*)(\d+)/, " \\1\\2 ").strip.split(/ +/)
      # puts @args

      @drop_lowest = false
      @drop_lowest = !!(@raw_expression =~ /D/)

      @reroll_ones = false
      @reroll_ones = @args.includes?("r")

      if @args.includes?("x")
        _meh = @args.index("x")
        unless _meh.nil?
          iterations_index = _meh - 1
          @iterations = @args[iterations_index].to_i
        end
      end

      @modifier = @args.last.to_i if @args.last =~ /^[\+\-]/

      if @args.includes?("d")
        _meh = @args.index("d")

        unless _meh.nil?
          casts_index = _meh - 1
          @casts = @args[casts_index].to_i

          die_index = _meh - 1
          @die = @args[die_index].to_i
        end
      end

    end

    def sanity_check!
      @iterations = 1      if @iterations < 1 || @iterations > 30
      @die = 20            if @die < 1
      @casts = 1           if @casts < 1
      @drop_lowest = false if @casts == 1
    end

    def modifier_to_s : String
      case @modifier <=> 0
      when -1
        @modifier.to_s
      when 1
        "+#{@modifier}"
      else
        ""
      end
    end

    def reroll_ones_to_s : String
      @reroll_ones ? "r" : ""
    end

    def to_s : String
      "#{@casts}d#{@die}#{reroll_ones_to_s}#{modifier_to_s}"
    end

    def casts : Int32
      @casts
    end

    def iterations : Int32
      @iterations
    end

    def die : Int32
      @die
    end

    def modifier : Int32
      @modifier
    end

    def drop_lowest : Bool
      @drop_lowest
    end

    def reroll_ones : Bool
      @reroll_ones
    end

  end
end
