class PlayerUserTokensController < ApplicationController
  before_filter :find_player, :only => [:show]

  def show
    deny_access unless @player.can_show_user_token?(current_user)

    respond_to do |format|
      format.json
    end
  end

  private
  def find_player
    @player = Player.find(params[:player_id])
  end
end