require 'test_helper'

class SequenceTest < ActiveSupport::TestCase
  context "A sequence that is completed" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 1)
      @game.start
      @sequence = @game.sequences.first
      Factory(:sentence, :sequence => @sequence, :player => @sequence.player)
    end

    should "not pass itself to the next player" do
      assert_nil @sequence.player
    end
  end
  
  context "A sequence" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 3)
      @player = @game.players.first
      @game.start
      @sequence = @player.sequences.first
    end

    should "should have a next_play_position of 1 when created" do
      assert_equal 1, @sequence.next_play_position
    end

    should "should have a next_play_position of 2 after the first play" do
      Factory.create(:sentence, :sequence => @sequence, :player => @player)
      assert_equal 2, @sequence.next_play_position
    end

    should "should have a next_play_position of 3 after the second play" do
      Factory.create(:sentence, :sequence => @sequence, :player => @player)
      Factory.create(:drawing, :sequence => @sequence, :player => @player)
      assert_equal 3, @sequence.next_play_position
    end

    should "should not allow two plays with the same position" do
      @play = Factory.create(:sentence, :sequence => @sequence, :player => @player)
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:drawing, :sequence => @sequence, :player => @player, :position => @play.position)
      end
    end

    should "not allow the first play to have a non-sequential position" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:sentence, :sequence => @sequence, :player => @player, :position => @sequence.next_play_position + 1)
      end
    end

    should "should not allow a play to have a non-sequential position" do
      Factory.create(:sentence, :sequence => @sequence, :player => @player)
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:drawing, :sequence => @sequence, :player => @player, :position => @sequence.next_play_position + 1)
      end
    end
  end
end
