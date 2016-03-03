defmodule RollerExpression do
  defstruct sets: 1, n_sided_die: 20, reroll_ones: false, iterations: 1, drop_lowest: false, modifier: 0

  def parse(arg) do
    enum = String.split(String.strip(String.replace(String.replace(String.replace(arg, ~r/([0-9]+)/, " \\1 "), ~r/([\+\-])/, " \\1 "), ~r/ +/, " ")), " ")

    drop_lowest = Enum.member?(enum, "D")
    reroll_ones = Enum.member?(enum, "r") || Enum.member?(enum, "R")

    iterations = if Enum.member?(enum, "x") || Enum.member?(enum, "X") do
      String.to_integer(Enum.at(enum, Enum.find_index(enum, &(&1 == "x" || &1 == "X")) - 1))
    else
      1
    end

    modifier = if Enum.member?(enum, "+") || Enum.member?(enum, "-") do
      String.to_integer(Enum.at(enum, Enum.find_index(enum, &(&1 == "+" || &1 == "-"))) <> Enum.at(enum, Enum.find_index(enum, &(&1 == "+" || &1 == "-")) + 1))
    else
      0
    end

    sets = String.to_integer(Enum.at(enum, Enum.find_index(enum, &(&1 == "d" || &1 == "D")) - 1))
    n_sided_die = String.to_integer(Enum.at(enum, Enum.find_index(enum, &(&1 == "d" || &1 == "D")) + 1))

    %RollerExpression{
      iterations: iterations,
      sets: sets,
      n_sided_die: n_sided_die,
      drop_lowest: drop_lowest,
      reroll_ones: reroll_ones,
      modifier: modifier
    }
  end
end
