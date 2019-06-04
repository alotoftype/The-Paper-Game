class PlayersController < ApplicationController
  before_filter :require_user
  before_filter :find_player

  def eject
    deny_access unless @player.can_eject?(current_user)

    respond_to do |format|
      if @player.eject!
        flash[:notice] = @player.user.login + " has been ejected from the game."
        update_payer_lists(@game)
        format.xml  { render :xml => @player }
      else
        flash[:failure] = @player.game.errors[:base].join(' ')
        format.xml  { render :xml => @player.errors, :status => :unprocessable_entity }
      end
      format.html { redirect_to @player.game  }
    end
  end

  private

  def find_player
    @player = Player.find(params[:id])
  end
end

