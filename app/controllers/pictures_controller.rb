class PicturesController < ApplicationController
  before_filter :require_user
  before_filter :find_picture, :only => :show

  def show
    deny_access unless @picture.can_show?(current_user)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @picture }
    end
  end

  private

  def find_picture
    @picture = Picture.find(params[:id])
  end

end

