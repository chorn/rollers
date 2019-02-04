require "./roller/*"

module Roller
  # class Roller
  #
  #   def expression : Expression
  #     @expression
  #   end
  #
  #   def casts : Array of Expression
  #     @casts
  #   end
  #
  #   def initialize(raw_expression : String)
  #     @expression = Expression.new raw_expression
  #     @casts = [] of Cast
  #
  #     expression.iterations.times.map do
  #       @casts << Cast.new expression
  #     end
  #   end
  #
  #   def to_s : String
  #     @casts.map do |s|
  #       "#{expression}: #{s}#{s.subtotal_to_s} = #{s.total}"
  #     end.join("\n")
  #   end
  #
  # end
end

# roll = Roller::Roll.new 100, true
# puts roll.die
# puts roll.result
# puts roll.reroll_ones

# expression = Roller::Expression.new "6x4D6r+3"
# puts "casts: #{expression.casts}"
# puts "iterations: #{expression.iterations}"
# puts "die: #{expression.die}"
# puts "modifier: #{expression.modifier}"
# puts "drop_lowest: #{expression.drop_lowest}"
# puts "reroll_ones: #{expression.reroll_ones}"

# if ARGV.size == 0
#   puts "No roller expressions specified, try: 1d20 or 4D6r1 or 2d8+4"
#   exit
# end
#
# ARGV.map do |arg|
#   puts arg
#   roll = Roller::Roller.new arg
#   puts roll.to_s
# end
