class GameMessage < ActiveRecord::Base
  belongs_to :game
  belongs_to :user
  belongs_to :player
  validate :user_must_exist, :game_must_exist
  validates :message, :length => { :minimum => 1 }
  validates_presence_of :user, :game

  include GameMessageAuthorization

  scope :with_user, joins(:user).
    select('"users"."login", "game_messages".*').
    order(:created_at)

  # Validation

  def validate_destroy(user)
    permitted = can_destroy?(user)
    errors.add(:game_message, 'could not be removed. Sorry!') if not permitted
    return permitted
  end

  private

  def user_must_exist
    errors.add(:user, 'must point to an existing user.') if self.user_id && self.user.nil?
  end

  def game_must_exist
    errors.add(:game, 'must point to an existing game.') if self.game_id && self.game.nil?
  end
end