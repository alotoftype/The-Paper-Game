require 'test_helper'

class ColorTest < ActiveSupport::TestCase
  context "Across 128 sequential seed values, a list of colors" do
    setup do
      @color_sets = (0..127).collect { |i| Game.player_colors_from_seed(i) }
    end

    should "always have 16 values in each list" do
      assert_equal 0, @color_sets.find_all { |colors| colors.length != 16 }.length
    end

    should "always be unique within a single list" do
      assert_equal 0, @color_sets.find_all { |colors| colors.uniq.length != 16 }.length
    end

    should "each be distinct from one another" do
      assert_equal 128, @color_sets.uniq.length
    end
  end
  
  context "Across 255 sequential seed values, a list of colors" do
    setup do
      @color_sets = (0..255).collect { |i| Game.player_colors_from_seed(i) }
    end

    should "always have 16 values in each list" do
      assert_equal 0, @color_sets.find_all { |colors| colors.length != 16 }.length
    end

    should "always be unique within a single list" do
      assert_equal 0, @color_sets.find_all { |colors| colors.uniq.length != 16 }.length

    end

    should "only have 128 distinct lists" do
      assert_equal 128, @color_sets.uniq.length
    end
    
    should "be cyclical, wrapping at 128" do
      assert_equal @color_sets[0], @color_sets[128]
    end
  end
end