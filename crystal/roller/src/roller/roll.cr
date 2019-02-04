module Roller
  class Roll
    def initialize(@die : Int32 = 20, @reroll_ones : Bool = false)
      if @die < 1
        raise ArgumentError.new("Only positive integers are supported.")
      end

      @result = 0
      @result = straight_roll

      while @reroll_ones && @result == 1
        @result = straight_roll
      end
    end

    def die : Int32
      @die
    end

    def result : Int32
      @result
    end

    def reroll_ones : Bool
      @reroll_ones
    end

    def straight_roll : Int32
      rand(@die) + 1
    end
  end
end
