class Friend < ActiveRecord::Base
  belongs_to :user
  belongs_to :friend, :class_name => 'User', :foreign_key => 'friend_user_id'
  validate :user_must_exist, :friend_must_exist, :cannot_friend_self
  validates_presence_of :user, :friend
  validates_uniqueness_of :friend_user_id, :scope => :user_id

  # Validation

  private

  def user_must_exist
    errors.add(:user, 'must point to an existing user.') if self.user_id && self.user.nil?
  end

  def friend_must_exist
    errors.add(:friend, 'must point to an existing user.') if self.friend_user_id && self.friend.nil?
  end

  def cannot_friend_self
    errors.add(:friend, 'cannot be yourself.') if self.user_id == self.friend_user_id
  end
end