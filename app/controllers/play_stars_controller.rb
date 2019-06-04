class PlayStarsController < ApplicationController
  before_filter :new_play_star_from_params, :only => [:create]
  before_filter :find_play_star, :only => [:destroy]
  before_filter :require_user

  def create
    deny_access unless @play_star.can_create?(current_user)
    respond_to do |format|
      if @play_star.save
        flash.now[:success] = 'Play starred! (Click again to undo.)'
        format.html {
          flash[:success] = 'Play starred! (Click again to undo.)'
          @game =  @play_star.play.game(true)
          redirect_to @game
        }
      else
        format.html {
          flash[:error] = 'The play could not be starred. Please try again.'
          redirect_back_or_default root_url
        }
      end
      format.js   { render :layout => false }
      format.xml  { render :xml => @play }
    end
  end
  
  def destroy
    respond_to do |format|
      if @play_star.validate_destroy(current_user) and @play_star.delete
        flash.now[:success] = 'Star removed! (Click again to undo.)'
        format.html {
          flash[:success] = 'Star removed! (Click again to undo.)'
          @game =  @play_star.play.game(true)
          redirect_to @game
        }
      else
        format.html {
          flash[:error] = 'The play could not be unstarred. Please try again.'
          redirect_back_or_default root_url
        }
      end
      format.js   { render :layout => false }
      format.xml  { render :xml => @play }
    end
  end

  private
  def new_play_star_from_params
    @play_star = PlayStar.new()
    @play_star.user = current_user
    @play_star.play = Play.find(params[:play_id])
  end

  def find_play_star
    @play_star = PlayStar.where{ |ps| (ps.user_id == current_user.id) & (ps.play_id == params[:play_id]) }.first
  end
end

