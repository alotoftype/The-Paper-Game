class Player < ActiveRecord::Base
  belongs_to :game, :counter_cache => true
  belongs_to :user
  has_many :plays, :autosave => true
  has_many :sequences
  has_many :game_messages
  validate :game_must_exist, :user_must_exist
  validates_presence_of :game, :user, :position
  validates_uniqueness_of :position, :scope => :game_id
  validates_uniqueness_of :user_id, :scope => :game_id
  before_validation :auto_assign_position, :auto_assign_color

  # Helper Sets

  scope :for_display, lambda { |user|
    if (user)
      return order(:position).joins(:user).
        joins('LEFT JOIN "friends" ON "friends"."friend_user_id" = "users"."id" AND "friends"."user_id" = %{user_id}' % { :user_id => user.id}).
        joins('LEFT JOIN "blocks" ON "blocks"."blocked_user_id" = "users"."id" AND "blocks"."user_id" = %{user_id}' % { :user_id => user.id}).
        select('players.*, users.login, friends.user_id AS is_friend, blocks.user_id AS is_blocked')
    else
      return order(:position).joins(:user).select('players.*, users.login, NULL AS is_friend, NULL AS is_blocked')
    end
  }
  
  # Access Control

  def self.can_eject(user)
    where(:is_ejected => false).joins(:game).merge(Game.can_update(user))
  end

  def can_eject?(user)
    return false if user == nil || user.id == self.user_id
    Player.can_eject(user).exists?(self)
  end

  def can_show_user_token?(user)
    return false if user == nil
    players = Player.where{|p| p.id == self.id}
    PlayerUserTokenAuthorization.can_show?(user) and
      PlayerUserTokenAuthorization.can_show(user, players).exists?
  end

  # Helper Properties

  def pending_plays
    if (!@pending_plays)
      @pending_plays = Array.new
      self.sequences.with_next_play_pos.each do |sequence|
        play = Play.new(:sequence => sequence, :player => self, :position => sequence.next_play_pos)
        play.picture = Picture.new if play.is_picture?
        @pending_plays << play
      end
    end
    @pending_plays
  end

  def pending_play
    return nil if !pending_plays
    pending_plays.first
  end

  def current_round(game = nil)
    game ||= self.game
    if !game.has_started?
      return 0
    end
    return (self.plays.maximum('position') || 0) + 1
  end

  def next_player
    players = self.game.players.where(:is_ejected => false)
    if players.maximum(:position) == (self.position)
    	return players.where(:position => players.minimum(:position)).order(:position).first
    else
      return players.where(:position => players.where{|p| p.position > self.position}.minimum(:position)).order(:position).first
    end
  end

  def is_next_play_picture?
    pending_play && pending_play.is_picture?
  end

  def is_next_play_sentence?
    pending_play && pending_play.is_sentence?
  end

  # Mutating Methods

  def add_sentence(sentence)
    self.plays.build(:player => self, :sequence => self.sequences.first, :sentence => sentence)
  end

  def eject!
    Game.transaction do
      pass_on_plays if (self.sequences.any?)
      self.is_ejected = true
      self.save!
    end
  end

  def leave!
    Game.transaction do
      pass_on_plays if (self.sequences.any?)
      if (self.game.has_started?)
        self.is_ejected = true
        return self.save
      end
      self.delete
    end
  end

  private

  def pass_on_plays
    next_player = self.next_player
    if next_player.sequences.any?
      queue_position = next_player.sequences.maximum(:queue_position) + 1
    else
      queue_position = 1
    end
    self.sequences.order(:queue_position).each do |sequence|
      sequence.queue_position = queue_position
      sequence.player_id = next_player.id
      sequence.save!
      queue_position = queue_position + 1
    end
  end

  def auto_assign_position
    if self.position.nil? && self.game
      self.position = self.game.next_player_position
    end
  end

  def auto_assign_color
    if self.color.nil? && self.game
      self.color = self.game.player_color(self.position)
    end
  end

  # Validation

  def game_must_exist
    errors.add(:game, 'must point to an existing game.') if self.game_id && self.game.nil?
  end

  def user_must_exist
    errors.add(:user, 'must point to an existing user.') if self.user_id && self.user.nil?
  end
end
