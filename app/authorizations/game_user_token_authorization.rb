module GameUserTokenAuthorization

  @@default_games = Game.scoped

  def self.can_show?(user)
    if user then true else false end
  end

  def self.can_show(user, games = @@default_games)
    return none unless can_show?(user)
    games.where{|g| Player.where{|p| (p.user_id == user.id)}.where('"players"."game_id" = "games"."id"').exists}
  end
end