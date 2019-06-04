class PlayStar < ActiveRecord::Base
  belongs_to :user
  belongs_to :play
  validate :user_must_exist, :play_must_exist, :cannot_star_self
  validates_presence_of :user, :play
  validates_uniqueness_of :play_id, :scope => :user_id
  
  @@destroy_time_limit = 5

  # Access Control

  def self.can_create?(user)
    if user then true else false
    end
  end

  def self.can_destroy?(user)
    if user then true else false
    end
  end

  scope :can_destroy, (lambda do |user|
    where{ |ps| (ps.user_id == user.id) & (ps.created_at > @@destroy_time_limit.minutes.ago) }
  end)

  def can_create?(user)
    PlayStar.can_create?(user) and
      self.user_id == user.id and
      self.play.sequence.game.players.where{user_id == my{user.id}}.exists? and
      self.play.player.user_id != user.id
  end

  def can_destroy?(user)
    PlayStar.can_destroy?(user) and
      user_id == user.id and created_at > @@destroy_time_limit.minutes.ago
  end
  
  # Validation
  
  def validate_destroy(user)
    permitted = can_destroy?(user)
    errors.add(:star, 'could not be removed. Sorry!') if not permitted
    return permitted
  end

  private

  def user_must_exist
    errors.add(:user, 'must point to an existing user.') if self.user_id && self.user.nil?
  end

  def play_must_exist
    errors.add(:play, 'must point to an existing play.') if self.play_id && self.play.nil?
  end

  def cannot_star_self
    errors.add(:play, 'cannot be your own play.') if self.play && self.user_id == self.play.player.user_id
  end
end