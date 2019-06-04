class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:logout, :destroy]

  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])

    respond_to do |format|
      if @user_session.save && UserSession.find.user
        flash.now[:success] = 'Login successful.'
        format.html {
          flash[:success] = flash.now[:success]
          redirect_back_or_default root_url
        }
        format.xml  { render :xml => @user_session, :status => :created, :location => @user_session }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user_session.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @user_session = current_user_session
    @user_session.destroy

    respond_to do |format|
        flash[:success] = 'Logout successful.'
      format.html { redirect_back_or_default root_url }
      format.xml  { head :ok }
    end
  end
end