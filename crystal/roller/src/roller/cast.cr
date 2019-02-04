module Roller
  class Cast

    def initialize(expression : Expression)
      @rolls = [] of Int32
      @die = 1
      @die = expression.die
      @drop_lowest = false
      @drop_lowest = expression.drop_lowest
      @modifier = 0
      @modifier = expression.modifier
      @rolls = [] of Roll

      expression.casts.times do
        roll = Roll.new @die, expression.reroll_ones
        @rolls << roll
      end

      @lowest = 0
      # @lowest = @drop_lowest ? @rolls.min : 0
      @dropped = false
      @width = 1
      @width = @die.to_s.size + 2
      @subtotal = 0
      @total = 0
      # @subtotal = rolls.inject(0, :+) - @lowest
      @total = @subtotal + @modifier
    end

    def subtotal_to_s
      case @modifier <=> 0
      when -1
        " = #{roll_to_s(@subtotal)} - #{@modifier.abs}"
      when 1
        " = #{roll_to_s(@subtotal)} + #{@modifier}"
      when 0
        ""
      end
    end

    def roll_to_s(roll)
      sprintf "%#{@width}s",
        if !@dropped && roll == @lowest
          @dropped = true
          "[#{roll}]"
        else
          roll.to_s
        end
    end

    def to_s
      rolls.map { |roll| roll_to_s(roll) }.join(" + ")
    end

    def rolls : Int32
      @rolls
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

    def total
      @total
    end

    def subtotal
      @subtotal
    end

  end
end
