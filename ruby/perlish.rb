#!/usr/bin/env ruby


def roller(orignal_spec)
  rtn = []
  sets, iterations, die, modifier, drop, reroll, totals = 1, 1, 20, 0, false, false, false
  spec = orignal_spec.dup

  if spec.gsub!(/([+-]\d+)$/, '')
    modifier = $&.to_i
  end

  if spec.gsub!(/[rR]$/, '')
    reroll = true
  end

  drop = true if spec =~ /D/

  if spec.gsub!(/^(\d+)[xX]/, '')
    sets = $&.to_i
  elsif spec.gsub!(/[xX](\d+)$/, '')
    sets = $&.to_i
  end

  if spec =~ /(\d+)[dD](\d+)/
    iterations = $1.to_i
    die = $2.to_i
  end

  iterations = 1 if iterations < 1 || iterations > 30
  die = 20       if die < 1 || die > 1000000000
  sets = 6       if sets < 1 || sets > 40
  drop = false   if iterations == 1

  width = die.to_s.length

  1.upto(sets) {
    scores = []
    lowest = die
    total = 0
    shown = 0

    1.upto(iterations) {
      if reroll and (die != 1)
        rand_num = 1
        rand_num = Kernel.rand(die)+1 while rand_num == 1
      else
        rand_num = Kernel.rand(die)+1
      end

      lowest = rand_num if rand_num < lowest
      scores.push rand_num
    }

    rtn << iterations.to_s + "d" + die.to_s
    rtn << "r" if reroll

    if modifier != 0
      rtn << "+" if modifier > 0
      rtn << "-" if modifier < 0
      rtn << modifier.abs.to_s
    end

    rtn << ": "

    scores.each { |score|
      shown += 1
      rtn << " + " if shown > 1 and !totals

      if (score == lowest) and drop
        rtn << sprintf("[%" + width.to_s + "s]", score) if !totals

        lowest = -1
      else
        if !totals and (iterations > 1)
          rtn << " " if drop
          rtn << sprintf("%" + width.to_s + "s", score)
          rtn << " " if drop
        end

        total += score
      end
    }

    rtn << " = " if !totals and iterations > 1

    if (modifier != 0)
      if !totals
        rtn << sprintf("%" + (width+1).to_s + "s ", total)
        rtn << '+' if modifier > 0
        rtn << '-' if modifier < 0
        rtn << " " + modifier.abs.to_s + " = "
      end

      total += modifier
    end

    rtn << sprintf("%" + (width+1).to_s + "s\n", total)
  }

  return rtn.join
end

#---------------------------------------------------------------------

ARGV.each do |expression|
  puts roller(expression)
end

