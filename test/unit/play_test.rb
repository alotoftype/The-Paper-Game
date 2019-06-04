require 'test_helper'

class PlayTest < ActiveSupport::TestCase
  context "A sentence" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 3)
      @player = @game.players.first
      @game.start
      @sequence = @player.sequences.first
    end
    
    should "should be at least 10 characters long" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:play, :sentence => '123456789', :sequence => @sequence, :player => @player)
      end
    end
    
    should "should be accepted if it is at least 10 characters long" do
      assert_nothing_raised ActiveRecord::RecordInvalid do
        Factory.create(:play, :sentence => '1234567890', :sequence => @sequence, :player => @player)
      end
    end
  end

  context "A play" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 3)
      @player = @game.players.first
      @game.start
      @sequence = @player.sequences.first
    end
    
    should "be either a picture or a sentence, not both" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:play, :sentence => 'This is a sentence.', :picture => Factory(:picture), :sequence => @sequence, :player => @player)
      end
    end
    
    should "be either a picture or a sentence, not neither" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:play, :sequence => @sequence, :player => @player)
      end
    end
    
    should "require a sequence" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:play, :player => @player)
      end
    end
    
    should "require a player" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:play, :sequence => @sequence)
      end
    end
  end
  
  context "The first play in a sequence" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 3)
      @player = @game.players.first
      @game.start
      @sequence = @player.sequences.first
    end
    
    should "be a sentence" do
      assert_nothing_raised ActiveRecord::RecordInvalid do
        Factory.create(:sentence, :sequence => @sequence, :player => @player)
      end
    end

    should "not be a picture" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:drawing, :sequence => @sequence, :player => @player)
      end
    end
    
    should "have a position of 1" do
      @play = Factory.create(:sentence, :sequence => @sequence, :player => @player)
      assert_equal 1, @play.position
    end
  end
  
  context "The second play in a sequence" do
    setup do
      @game = Factory(:game, :player_limit => 1, :round_limit => 3)
      @player = @game.players.first
      @game.start
      @sequence = @player.sequences.first
      Factory.create(:sentence, :sequence => @sequence, :player => @player)
    end
    
    should "be a picture" do
      assert_nothing_raised ActiveRecord::RecordInvalid do
        Factory.create(:drawing, :sequence => @sequence, :player => @player)
      end
    end

    should "not be a sentence" do
      assert_raise ActiveRecord::RecordInvalid do
        Factory.create(:sentence, :sequence => @sequence, :player => @player)
      end
    end
    
    should "have a position of 2" do
      @play = Factory.create(:drawing, :sequence => @sequence, :player => @player)
      assert_equal 2, @play.position
    end
  end
end