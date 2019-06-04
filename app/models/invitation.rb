class Invitation < ActiveRecord::Base
  belongs_to :game
  belongs_to :invitee, :class_name => 'User', :foreign_key => 'invitee_user_id'
  belongs_to :inviter, :class_name => 'User', :foreign_key => 'inviter_user_id'
  validate :game_must_exist, :invitee_must_exist, :inviter_must_exist
  validate :cannot_duplicate_player, :on => :create
  validates_presence_of :game, :invitee, :inviter
  validates_uniqueness_of :invitee_user_id, :scope => :game_id

  scope :alive,
    where(:has_accepted => nil).joins(:game).merge(Game.open)

  # Access Control

  def self.can_accept(user)
    return alive.where(:invitee_user_id => user.id) if (user)
    return where("0 = 1")
  end

  def self.can_decline(user)
    can_accept(user)
  end

  def self.can_create?(user)
    if user
      return true
    end
    return false
  end

  def self.can_new?(user)
    can_create?(user)
  end

  def can_accept?(user)
    Invitation.can_accept(user).exists?(self)
  end

  def can_decline?(user)
    Invitation.can_decline(user).exists?(self)
  end

  def can_create?(user)
    return false if user == nil
    Game.open.joins{players}.where{players.user_id == user.id}.
      where{ (players.is_creator == true) | (is_private == false) | (is_open_invitation == true) }.
      exists?(self.game)
  end

  def can_new?(user)
    can_create?(user)
  end
  
  # Mutating Methods

  def accept
    Game.transaction do
      self.has_accepted = true;
      self.game.add_player(self.invitee)

      Invitation.transaction do
        self.save!
        self.game.save!
      end
    end
  end

  private
  
  # Validation

  def game_must_exist
    errors.add(:game, 'must point to an existing game.') if self.game_id && self.game.nil?
  end

  def invitee_must_exist
    errors.add(:invitee, 'must point to an existing user.') if self.invitee_user_id && self.invitee.nil?
  end

  def inviter_must_exist
    errors.add(:inviter, 'must point to an existing user.') if self.inviter_user_id && self.inviter.nil?
  end

  def cannot_duplicate_player
    if self.invitee_user_id == self.inviter_user_id
      errors.add(:invitee, 'cannot be yourself.')
    elsif game.players.exists?(:user_id => self.invitee_user_id)
      errors.add(:invitee, 'is already in the game.')
    elsif game.invitations.exists?(:invitee_user_id => self.invitee_user_id)
      errors.add(:invitee, 'has already been invited.')
    end
  end
end

