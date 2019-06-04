class PasswordResetsController < ApplicationController
  before_filter :require_no_user
  before_filter :load_user_using_perishable_token, :only => [:edit, :update]

  def new
    @user = User.new

    respond_to do |format|
      format.html
      format.xml { render :xml => @user }
    end
  end

  def create
    @user = User.find_by_smart_case_login_field params[:user][:login]
    respond_to do |format|
      if @user
        @user.reset_perishable_token!
        Notifier.password_reset_instructions(@user).deliver
        flash.now[:notice] = "Instructions to reset your password have been emailed to you."
        format.html {
          flash[:notice] =  flash.now[:notice]
          flash[:mail] =  flash.now[:mail]
          redirect_to root_url
        }
        format.xml  { head :ok }
      else
        flash.now[:notice] = "No user was found with that login name."
        format.html {
          flash[:notice] =  flash.now[:notice]
          redirect_to new_account_password_reset_url
        }
        format.xml  { head :ok }
      end
    end
  end

  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    respond_to do |format|
      if @user.login.downcase != params[:user][:login].downcase
        flash.now[:failure] = 'Login does not match.'
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      elsif @user.save
        Notifier.password_changed_notification(@user).deliver
        flash.now[:success] = "Password successfully updated!"
        format.html {
          flash[:success] = flash.now[:success]
          flash[:mail] = flash.now[:mail]
          redirect_to @user
        }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  private
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:notice] = "We're sorry, but we could not locate your account. " +
          "If you are having issues try copying and pasting the URL " +
          "from your email into your browser or restarting the " +
          "reset password process."
      redirect_to root_url
    end
  end
end
