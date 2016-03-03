defmodule RollerCli do

  def main([]) do
    IO.puts "No roller expressions specified, try: 1d20 or 4D6r1 or 2d8+4"
  end

  def main(args) do
    args
      |> Enum.map(&RollerExpression.parse(&1))
      |> Enum.map(&Roller.spawn_rolls(&1))
  end

end
