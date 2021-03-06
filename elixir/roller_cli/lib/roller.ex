defmodule Roller do

  def roll_a_die(n_sided_die), do: roll_a_die(n_sided_die, false)
  def roll_a_die(1, _), do: 1
  def roll_a_die(n_sided_die, false), do: :rand.uniform(n_sided_die)

  def roll_a_die(n_sided_die, true) do
    maybe = roll_a_die(n_sided_die)

    result = cond do
      maybe == 1 ->
        roll_a_die(n_sided_die, true)
      true ->
        maybe
    end

    result
  end

  def spawn_roll_a_die(_, n_sided_die, reroll_ones) do
    parent = self()

    spawn_link fn -> send(parent, { :roll, roll_a_die(n_sided_die, reroll_ones) } ) end

    roll = receive do
      {:roll, response} -> response
    end

    roll
  end

  def find_index_of_minimum(rolls, n_sided_die) do
    min = Enum.reduce(rolls, n_sided_die, fn(element, acc) -> if(element < acc, do: element, else: acc) end)
    Enum.find_index(rolls, &(&1 == min))
  end

  def format_by_width(value, width) do
    to_string(:io_lib.format("~-#{width}s", ["#{value}"]))
  end

  def format_a_roll(roll, width) do
    format_a_roll(roll, width, false)
  end

  def format_a_roll(roll, width, false) do
    format_by_width(" #{roll} ", width + 2)
  end

  def format_a_roll(roll, width, true) do
    format_by_width("[#{roll}]", width + 2)
  end

  def format_a_set(set_of_rolls, index_of_minimum, width) do
    for {roll, index} <- Enum.with_index(set_of_rolls) do
      format_a_roll(roll, width, index == index_of_minimum)
    end
    |> Enum.intersperse(" + ")
  end

  def format_the_modifier(_, 0), do: ""
  def format_the_modifier(adjusted, modifier) do
    plus_minus = fn(modifier) -> if modifier < 0, do: "-", else: "+" end
    " = #{adjusted} #{plus_minus.(modifier)} #{abs(modifier)}"
  end

  def roll_a_set_of_dice(n_sided_die, reroll_ones, sets, drop_lowest, modifier) do
    formatted_r = fn(reroll) -> if reroll, do: "r", else: "" end
    formatted_m = fn
      modi when modi > 0 -> "+#{modi}"
      modi when modi < 0 -> "#{modi}"
      modi when modi == 0 -> ""
    end
    used_minimum = fn(drop, set) -> if drop, do: Enum.min(set), else: 0 end
    used_index_of_minimum = fn(drop, set) -> if drop, do: Roller.find_index_of_minimum(set, n_sided_die), else: Enum.count(set) + 1 end

    set_of_rolls = 1..sets |> Enum.map(&Roller.spawn_roll_a_die(&1, n_sided_die, reroll_ones))
    sum = Enum.sum(set_of_rolls)
    adjusted = sum - used_minimum.(drop_lowest, set_of_rolls)
    width = String.length(to_string(n_sided_die))
    expression = "#{sets}d#{n_sided_die}#{formatted_r.(reroll_ones)}#{formatted_m.(modifier)}"
    formatted_set = Enum.join(format_a_set(set_of_rolls, used_index_of_minimum.(drop_lowest, set_of_rolls), width))

    "#{expression}: #{formatted_set} #{format_the_modifier(adjusted, modifier)} = #{adjusted + modifier}"
  end

  def roll_a_set_of_dice(expression) do
    roll_a_set_of_dice(expression.n_sided_die, expression.reroll_ones, expression.sets, expression.drop_lowest, expression.modifier)
  end

  def spawn_rolls(expression) do
    parent = self()

    Enum.map(
      1..expression.iterations,
      &spawn_link fn -> send(parent, { &1, Roller.roll_a_set_of_dice(expression) }) end
    )

    Enum.map(
      1..expression.iterations,
      &receive do
        {&1, set} -> IO.puts set
      end
    )
  end
end
