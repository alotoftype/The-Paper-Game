require 'test_helper'

class GameUserTest < ActiveSupport::TestCase
  context "A player" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 3)
      @player = @game.players.first
    end

    should "have an current_round of 0 before the game has started" do
      assert_equal 0, @game.players.first.current_round
    end

    should "have a current_round of 1 immediately after the game has started" do
      @game.start
      assert_equal 1, @game.players.first.current_round
    end

    should "have a current_round of 2 after they have made a move" do
      @game.start
      Factory(:sentence, :sequence => @player.sequences.first, :player => @player)
      assert_equal 2, @game.players.first.current_round
    end
  end
end
