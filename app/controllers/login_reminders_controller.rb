class LoginRemindersController < ApplicationController
  before_filter :require_no_user

  def new
    @user = User.new

    respond_to do |format|
      format.html
      format.xml { render :xml => @user }
    end
  end

  def create
    @user = User.where("lower(email) = ?", params[:user][:email].downcase).first
    respond_to do |format|
      if @user
        @user.reset_perishable_token!
        Notifier.login_reminder(@user).deliver
        flash.now[:notice] = "Your user name has been emailed to you."
        format.html {
          flash[:notice] =  flash.now[:notice]
          flash[:mail] =  flash.now[:mail]
          redirect_to root_url
        }
        format.xml  { head :ok }
      else
        flash.now[:notice] = "No user was found with that email address."
        format.html {
          flash[:notice] =  flash.now[:notice]
          redirect_to new_account_login_reminder_url
        }
        format.xml  { head :ok }
      end
    end
  end
end
