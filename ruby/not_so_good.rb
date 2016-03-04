#!/usr/bin/env ruby

# This is pretty awful.

module Roller
  class Expression
    attr_reader :sets, :iterations, :die, :modifier, :drop_lowest, :reroll_ones, :total

    def initialize(raw_expression)
      @iterations = 1
      @modifier = 0

      parse!(raw_expression)
    end

    def parse!(raw_expression)
      args = split_raw_expression(raw_expression)

      @drop_lowest = !!(raw_expression =~ /D/)
      @reroll_ones = args.member?('r')
      @iterations = args[args.find_index('x') - 1].to_i if args.member?('x')
      @modifier = args.last.to_i if args.last =~ /^[\+\-]/

      @sets = args[args.find_index('d') - 1].to_i
      @die = args[args.find_index('d') + 1].to_i

      @iterations = 1 if @iterations < 1 || @iterations > 30
      @die = 20       if @die < 1 || @die > 1000000000
      @sets = 1       if @sets < 1 || @sets > 40
      @drop_lowest = false if @sets == 1
    end

    def split_raw_expression(raw)
      raw.downcase.gsub(/ +/, '').gsub(/([\-\+]*)(\d+)/, ' \1\2 ').strip.split(/ +/)
    end

    def modifier_to_s
      case modifier <=> 0
      when -1
        modifier.to_s
      when 1
        "+#{modifier}"
      else
        ""
      end
    end

    def reroll_ones_to_s
      @reroll_ones ? "r" : ""
    end

    def to_s
      "#{sets}d#{die}#{reroll_ones_to_s}#{modifier_to_s}"
    end
  end

  class Roll
    attr_reader :die, :result

    def initialize(die, reroll_ones = false)
      @die = die
      @result = straight_roll

      while reroll_ones && @result == 1 do
        @result = straight_roll
      end
    end

    def straight_roll
      rand(die) + 1
    end
  end

  class Set
    attr_reader :rolls, :die, :drop_lowest, :modifier, :total, :subtotal

    def initialize(expression)
      @rolls = []
      @die = expression.die
      @drop_lowest = expression.drop_lowest
      @modifier = expression.modifier
      @rolls = expression.sets.times.map{ Roll.new(die, expression.reroll_ones).result }
      @lowest = @drop_lowest ? @rolls.min : 0
      @dropped = false
      @width = @die.to_s.length + 2
      @subtotal = rolls.inject(0, :+) - @lowest
      @total = @subtotal + @modifier
    end

    def subtotal_to_s
      case @modifier <=> 0
      when -1
        " = #{roll_to_s(subtotal)} - #{@modifier.abs}"
      when 1
        " = #{roll_to_s(subtotal)} + #{@modifier}"
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
      rolls.map { |roll| roll_to_s(roll) }.join(' + ')
    end
  end

  class Roller
    attr_reader :expression, :sets

    def initialize(raw_expression)
      @expression = Expression.new(raw_expression)
      @sets = []

      @sets = expression.iterations.times.map do
        Set.new(expression)
      end
    end

    def to_s
      sets.map do |s|
        "#{expression}: #{s}#{s.subtotal_to_s} = #{s.total}"
      end.join("\n")
    end

  end
end

if ARGV.size == 0
  puts "No roller expressions specified, try: 1d20 or 4D6r1 or 2d8+4"
  exit
end

ARGV.map{ |arg| puts Roller::Roller.new(arg) }

