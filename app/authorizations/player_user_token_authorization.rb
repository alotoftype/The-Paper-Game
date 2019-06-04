module PlayerUserTokenAuthorization

  @@default_players = Player.scoped

  def self.can_show?(user)
    if user then true else false end
  end

  def self.can_show(user, players = @@default_players)
    return none unless can_show?(user)
    players.where{|p| p.user_id == user.id}
  end
end