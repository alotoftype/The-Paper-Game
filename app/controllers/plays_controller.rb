class PlaysController < ApplicationController
  before_filter :new_play_from_params, :only => :create

  def create
    deny_access unless @play.can_create?(current_user)
    respond_to do |format|
      failed_play = nil
      if @play.save
        flash.now[:success] = 'Your ' + (@play.is_picture? ? 'picture' : 'sentence') + ' has been sent.'
      else
        failed_play = @play
      end
      format.js   { render :layout => false }
      format.html {
        @game =  @play.sequence.game(true)
        render :template => 'games/show', :locals => { :failed_play => failed_play }
      }
      format.xml  { render :xml => @play }
    end
  end

  protected

  def new_play_from_params
    if params[:play][:picture_attributes] && params[:play][:picture_attributes][:image] === nil && params[:play][:picture_attributes][:image_base64]
      decoded_data = Base64.decode64(params[:play][:picture_attributes][:image_base64])

      data = StringIO.new(decoded_data)
      data.class_eval do
        attr_accessor :content_type, :original_filename
      end

      data.content_type = 'image/png'
      data.original_filename = 'blob.png'

      params[:play][:picture_attributes][:image] = data
      params[:play][:picture_attributes].delete(:image_base64)
    end
    @play = Play.new(params[:play])
  end
end

