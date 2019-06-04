class Block < ActiveRecord::Base
  belongs_to :user
  belongs_to :blocked_user, :class_name => 'User', :foreign_key => 'blocked_user_id'
  validate :user_must_exist, :blocked_user_must_exist, :cannot_block_self
  validates_presence_of :user, :blocked_user
  validates_uniqueness_of :blocked_user_id, :scope => :user_id

  # Validation

  private

  def user_must_exist
    errors.add(:user, 'must point to an existing user.') if self.user_id && self.user.nil?
  end

  def blocked_user_must_exist
    errors.add(:blocked_user, 'must point to an existing user.') if self.blocked_user_id && self.blocked_user.nil?
  end

  def cannot_block_self
    errors.add(:blocked_user, 'cannot be yourself.') if self.user_id == self.blocked_user_id
  end
end