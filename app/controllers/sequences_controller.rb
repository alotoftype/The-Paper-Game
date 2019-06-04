class SequencesController < ApplicationController
  before_filter :require_user
  before_filter :store_location
  before_filter :find_sequence

  def show
    deny_access unless @sequence.can_show?(current_user)
    respond_to do |format|
      if (@sequence)
        format.html { render 'games/show', :locals => { :sequence_position => params[:id] } }
        format.xml  { render :xml => @sequence }
      else
        format.html { redirect_to @game}
        format.xml  { render :xml => @game }
      end
    end
  end

  private

  def find_sequence
    @game = Game.find(params[:game_id])
    @sequence = @game.sequences.find_by_position(params[:id])
  end
end

