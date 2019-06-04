require 'test_helper'

class GameTest < ActiveSupport::TestCase
  context "A user" do
    setup do
      @user1 = Factory(:user)
      @game = Factory(:game, :creator => @user1, :player_limit => 2, :round_limit => 3)
    end

    should "be able to create a game" do
      assert_not_nil @game
    end

    should "be able to save a game" do
      assert_nothing_raised ActiveRecord::RecordInvalid do
        @game.save!
      end
    end
  end

  context "When joining a game, a user" do
    setup do
      @user1 = Factory(:user)
      @game = Factory(:game, :creator => @user1, :player_limit => 3)
    end

    should "not be able to join a game they created" do
      @game.add_player(@user1)
      assert_raise ActiveRecord::RecordInvalid do
        @game.save!
      end
    end

    should "be able to join another user's game" do
      @game.add_player(Factory(:user))
      assert_nothing_raised ActiveRecord::RecordInvalid do
        @game.save!
      end
    end

    should "not be able to join another user's game twice" do
      @user2 = Factory(:user)
      @game.add_player(@user2)
      @game.save!
      @game.add_player(@user2)
      assert_raise ActiveRecord::RecordInvalid do
        @game.save!
      end
    end

    should "not be able to join if the game is full" do
      @game.add_player(Factory(:user))
      @game.add_player(Factory(:user))
      @game.add_player(Factory(:user))
      assert_raise ActiveRecord::RecordInvalid do
        @game.save!
      end
    end
  end

  context "A game" do
    setup do
      @game = Factory(:game, :player_limit => 3)
    end

    should "be able to start" do
      @game.start
      assert !@game.errors.any?
    end

    should "issue an error if first try to start it twice" do
      @game.start
      @game.start
      assert @game.errors.any?
    end

    should "not have sequences before starting" do
      assert @game.sequences.any? == false
    end

    should "create sequences when starting" do
      @game.start
      assert @game.sequences.any?
    end

    should "not have sequences before starting" do
      assert_equal 0, @game.sequences.size
    end

    should "create 1 sequence for 1 player after starting" do
      @game.start
      assert_equal 1, @game.sequences.size
    end
    
    should "have the same value for the first color and the color of the first player" do
      assert_equal @game.player_colors[0], @game.players.first.color
    end
    
    should "have the same value for the second color and the color of the second player" do
      @game.add_player(Factory(:user))
      @game.save
      assert_equal @game.player_colors[1], @game.players.last.color
    end

    should "have a next_player_position of 2 when it's created" do
      assert_equal 2, @game.next_player_position
    end

    should "have a next_player_position of 3 after the second player has joined" do
      @game.add_player(Factory(:user))
      @game.save
      assert_equal 3, @game.next_player_position
    end

    should "have a next_player_position of 4 after the third player has joined" do
      @game.add_player(Factory(:user))
      @game.save
      @game.add_player(Factory(:user))
      @game.save
      assert_equal 4, @game.next_player_position
    end

    should "create 2 sequences for 2 players after starting" do
      @game.add_player(Factory(:user))
      @game.start
      assert_equal 2, @game.sequences.size
    end

    should "create 3 sequences for 3 players after starting" do
      @game.add_player(Factory(:user))
      @game.add_player(Factory(:user))
      @game.start
      assert_equal 3, @game.sequences.size
    end
  end

  context "A game" do
    setup do
      @user1 = Factory(:user)
      @user2 = Factory(:user)
      @game = Factory(:game, :creator => @user1, :player_limit => 2, :round_limit => 3)
      @game.add_player(@user2)
      @game.save
    end

    should "have an estimated_current_round of 0 before the game has started" do
      assert_equal 0, @game.estimated_current_round
    end

    should "have an estimated_current_round of 1 immediately after the game has started" do
      @game.start
      assert_equal 1, @game.estimated_current_round
    end

    should "have an estimated_current_round of 2 after the first player has made a move" do
      @game.start
      @player = @game.players.first
      Factory(:sentence, :sequence => @player.sequences.first, :player => @player)
      assert_equal 2, @game.estimated_current_round
    end
  end
end