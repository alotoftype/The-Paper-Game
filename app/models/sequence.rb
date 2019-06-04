class Sequence < ActiveRecord::Base
	belongs_to :game
	belongs_to :player
	has_many :plays, :autosave => true
	validates_presence_of :game, :position
  validate :game_must_exist, :player_must_exist, :check_queue_position
	validates_uniqueness_of :queue_position, :scope => :player_id, :if => :player_id, :message => 'can only be used for a single sequence.'
	validates_uniqueness_of :position, :scope => :game_id, :if => :game_id, :message => 'can only be used for a single sequence.'

  def self.bleed_delay
    7.days
  end

  # Helper Sets

  scope :with_next_play_pos,
    order(:queue_position).select('sequences.*, (SELECT COUNT(plays.id) FROM plays WHERE plays.sequence_id = sequences.id) + 1 AS next_play_pos')

  scope :bleeding,
      joins{ player.user }.
      joins{ game }.
      where{ updated_at < Sequence.bleed_delay.ago }.
      where{ (users.last_bled_at == nil) | (users.last_bled_at < 23.5.hours.ago) }.
      where('"sequences"."queue_position" = (SELECT MIN("s2"."queue_position") FROM "sequences" "s2" WHERE "s2"."player_id" = "sequences"."player_id")').
      readonly(false)

  # Access Control

  def self.can_show(user)
    joins(:game).
      where('%{user_id} IN (SELECT players.user_id FROM players WHERE players.game_id = sequences.game_id)' % { :user_id => user.id }).
      where{game.ended_at = nil}
  end

  def can_show?(user)
    Sequence.can_show(user).exists?(self)
  end

  # Helper Properties

  def bleed_risk
    [1, (Time.now - updated_at) / Sequence.bleed_delay].min
  end

  def to_param
    self.position.to_s
  end

	def first_in_queue?
	  self.player.sequences.order(:queue_position).first == self
	end

  def current_round
    self.plays.size
  end

  def next_play_position
    self.plays.count + 1
  end

  # Mutating Methods

  def bleed!(time)
    self.transaction do
      self.player.user.last_bled_at = time
      self.player.user.save!
      self.pass_to_next_player
      self.save!
    end
  end

  def pass_to_next_player
    if self.plays.count == self.game.round_limit
      self.queue_position = nil
      self.player = nil
    elsif
      self.player = self.player.next_player
      if self.player.sequences.any?
        self.queue_position = self.player.sequences.maximum(:queue_position) + 1
      else
        self.queue_position = 1
      end
    end
  end

  private

  # Validation

  def player_must_exist
    errors.add(:player, 'must point to an existing user.') if self.player_id && self.player.nil?
  end

  def check_queue_position
    errors.add(:queue_position, 'must be present for assigned sequences.') if self.player_id && self.queue_position.nil?
  end

  def game_must_exist
    errors.add(:game_id, 'must point to an existing game.') if self.game_id && self.game.nil?
  end
end

