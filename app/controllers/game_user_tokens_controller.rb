class GameUserTokensController < ApplicationController
  before_filter :find_game, :only => [:show]

  def show
    deny_access unless @game.can_show_user_token?(current_user)

    respond_to do |format|
      format.json
    end
  end

  private
  def find_game
    @game = Game.find(params[:game_id])
  end
end