module GamesHelper
  
  def back_to_game_path(game)
    if Regexp.new(game_path game) =~ session[:return_to] then session[:return_to] else (game_path game) end
  end
end
