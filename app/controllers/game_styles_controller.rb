class GameStylesController < ApplicationController
  before_filter :find_game, :only => [:show]

  def show
    deny_access unless @game.can_show?(current_user)

    respond_to do |format|
      format.css
    end
  end

  private
  def find_game
    @game = Game.find(params[:game_id])
  end
end