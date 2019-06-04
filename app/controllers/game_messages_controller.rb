class GameMessagesController < ApplicationController
  before_filter :new_game_message_from_params, :only => [:create]
  before_filter :find_game_message, :only => [:destroy]
  before_filter :require_user

  def create
    deny_access unless @game_message.can_create?(current_user)

    respond_to do |format|
      if @game_message.save
        flash.now[:success] = 'Message sent!'
        format.html {
          flash[:success] = 'Message sent!'
          @game =  @game_message.game(true)
          redirect_to @game
        }
      else
        format.html {
          flash[:error] = 'Your message was not sent. Please try again.'
          redirect_back_or_default root_url
        }
      end
      format.js   { render :layout => false }
      format.xml  { render :xml => @game }
    end
  end
  
  def destroy
    deny_access unless @game_message.can_destroy(user)

    respond_to do |format|
      if @game_message.validate_destroy(current_user) and @game_message.delete
        flash.now[:success] = 'Message deleted!'
        format.html {
          flash[:success] = 'Message deleted!'
          @game =  @game_message.game(true)
          redirect_to @game
        }
      else
        format.html {
          flash[:error] = 'The message could not be deleted. Please try again.'
          redirect_back_or_default root_url
        }
      end
      format.js   { render :layout => false }
      format.xml  { render :xml => @game }
    end
  end

  private
  def new_game_message_from_params
    @game_message = GameMessage.new(params[:game_message])
    @game_message.user = current_user
    @game_message.game = Game.find(params[:game_id])
    @game_message.player_id = @game_message.game.players.where{|p| p.user_id == current_user.id }.first.id
  end

  def find_game_message
    @game_message = GameMessage.where{ |gm| (gm.user_id == current_user.id) & (gm.id == params[:id]) }.first
  end
end

