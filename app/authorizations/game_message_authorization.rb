module GameMessageAuthorization

  @@default_set = GameMessage.scoped

  # Access Control

  @@destroy_time_limit = 5.minutes

  def self.can_create?(user)
    if user then true else false end
  end

  def self.can_destroy?(user)
    if user then true else false end
  end

  def self.can_destroy(user, set = @@default_set)
    return none unless can_destroy?(user)
    set.where{ |gm| (gm.user_id == user.id) & (gm.created_at > @@destroy_time_limit.minutes.ago) }
  end

  def can_create?(user, entity = self)
    GameMessageAuthorization.can_create?(user) and
      entity.game.players.where{user_id == my{user.id} && is_ejected == false}.exists?
  end

  def can_destroy?(user, entity = self)
    GameMessageAuthorization.can_destroy?(user) and
      entity.user_id == user.id and
      entity.created_at > @@destroy_time_limit.ago
  end
end