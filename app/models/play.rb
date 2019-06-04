class Play < ActiveRecord::Base
	belongs_to :player
	belongs_to :sequence
	belongs_to :picture
	has_one :game, :through => :sequence
	has_one :user, :through => :player
  has_many :stars, :class_name => 'PlayStar', :foreign_key => 'play_id'
	validates_presence_of :sequence, :player, :position
	validates_length_of :sentence, :minimum => 10, :allow_nil => true
	validate :sequence_must_exist, :player_must_exist, :picture_must_exist
	validates_uniqueness_of :position, :scope => :sequence_id, :message => 'can only be used for a single play.'
	validate :check_position_sequence, :must_be_first_in_queue, :player_and_sequence_from_same_game
	validate :type_must_match, :type_mutually_exclusive
	before_validation :auto_assign_player, :auto_assign_position
  after_save :update_sequence, :update_game
  accepts_nested_attributes_for :picture

  # Helper Sets

  scope :for_display, lambda { |sequence_position, user|
    joins(:player).
      joins('JOIN "users" ON "users"."id" = "players"."user_id"').
      joins('LEFT JOIN "play_stars" ON "play_stars"."play_id" = "plays"."id" AND "play_stars"."user_id" = %{user_id}' % { :user_id => user.id}).
      where(:sequences => {:position => sequence_position.to_i}).
      order(:position).
      select('plays.id, plays.sentence, plays.picture_id, users.login, play_stars.id AS star_id, players.id AS player_id, plays.position, CASE WHEN users.id = %{user_id} THEN NULL ELSE 1 END AS "user_can_star"' % { :user_id => user.id})
  }

  scope :random_sentence, lambda {
    where{sentence != nil}.offset(rand(where{sentence != nil}.count)).limit(1)
  }

  # Access Control

  def self.can_create?(user)
    if user then true else false
    end
  end

  def can_create?(user)
    sequence.player.user_id == user.id
  end

  def can_star?(user)
    self.sequence.game.players.where{user_id == my{user.id}}.exists? and
      self.player.user_id != user.id
  end

  # Helper Properties

  def color
    player.color
  end

  def is_sentence?
    self.position && self.position.odd?
  end

  def is_picture?
    self.position && self.position.even?
  end

  # Mutating Methods

  private

  def update_sequence
    self.sequence.pass_to_next_player
    self.sequence.save!
  end

  def update_game
    self.game.check_if_finished
    self.game.save!
  end

  def auto_assign_player
    if self.sequence && self.sequence.player && self.player.nil?
      self.player = self.sequence.player
    end
  end

  def auto_assign_position
    if self.sequence && self.position.nil?
      self.position = self.sequence.next_play_position
    end
  end

  # Validation

  public

  def append_errors_from_play(play)
    if play
      self.append_errors(play.errors)
      self.picture.append_errors(play.picture.errors) if self.picture && play.picture
    end
  end

  def append_errors(new_errors)
    if new_errors && new_errors.any?
      new_errors.each_pair { |key, key_errors| key_errors.each { |error| self.errors.add(key, error) } }
    end
  end
  
  private

  def must_be_first_in_queue
    errors.add(:base, 'You must act on the first play in your queue before you can make this play.') unless self.sequence && self.sequence.first_in_queue?
  end

  def type_must_match
    if self.is_picture? && self.picture.nil?
      if self.sentence
        errors.add(:base, 'This play requires a picture, not a sentence.')
      else
        errors.add(:picture, 'is required.')
      end
    elsif self.is_sentence? && self.sentence.nil?
      if self.picture
        errors.add(:base, 'This play requires a sentence, not a picture.')
      else
        errors.add(:sentence, 'is required.')
      end
    end
  end

  def type_mutually_exclusive
   errors.add(:base, 'a play can only have either a picture or a sentence.') unless self.picture.nil? || self.sentence.nil?
  end

  def check_position_sequence
    errors.add(:position, 'must be sequential.') unless self.position ==  1 || self.sequence && self.sequence.plays.where(:position => self.position - 1).any?
  end

  def sequence_must_exist
    errors.add(:sequence, 'must point to an existing user.') if self.sequence_id && self.sequence.nil?
  end

  def player_must_exist
    errors.add(:user, 'must point to an existing user.') if self.player_id && self.player.nil?
  end

  def picture_must_exist
    errors.add(:picture, 'must provide a picture.') if self.picture_id && self.picture.nil?
  end

  def player_and_sequence_from_same_game
    self.sequence && self.player && self.sequence.game_id == self.player.game_id
  end
end

