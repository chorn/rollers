require "../spec_helper"

describe Roller::Roll do

  it "exists" do
    roll = Roller::Roll.new
    roll.should be_a Roller::Roll
  end

  it "has a result" do
    roll = Roller::Roll.new
    roll.result.should be_a Int32
  end

  it "takes a die as an argument" do
    die = 123
    roll = Roller::Roll.new(die)
    roll.die.should eq die
  end

  it "rejects a negative die as an argument" do
    die = -1
    expect_raises(ArgumentError) do
      Roller::Roll.new(die)
    end
  end

  it "takes a die, reroll_ones as arguments" do
    die = 123
    reroll = true
    roll = Roller::Roll.new(die, reroll)
    roll.reroll_ones.should eq reroll
  end

  it "will reroll ones if directed" do
    die = 2
    reroll = true
    100.times do
      roll = Roller::Roll.new(die, reroll)
      roll.result.should_not eq 1
    end
  end

end
