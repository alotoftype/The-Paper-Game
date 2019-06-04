class AuthenticationsController < ApplicationController
  def create
    omniauth = request.env['omniauth.auth']
    authentication = Authentication.find_by_provider_and_uid(omniauth['provider'], omniauth['uid'])

    if authentication
      # User is already registered with application
      flash[:success] = 'Signed in successfully.'
      sign_in_and_redirect(authentication.user)
    elsif current_user
      # User is signed in but has not already authenticated with this social network
      current_user.authentications.create!(:provider => omniauth['provider'], :uid => omniauth['uid'])
      
      flash[:success] = 'Authentication successful.'
      redirect_back_or_default root_url
    elsif user = User.where("lower(email) = ?", omniauth['info']['email'].downcase).first
      # Email is already taken
      flash[:notice] = "The email address #{user.email} is already taken. Log in and go to your profile page to link your accounts."
      redirect_to login_path
    else
      # User is new to this application
      user = User.new
      if user.save_omniauth(omniauth)
        flash[:success] = 'User created and signed in successfully.'
        sign_in_and_redirect(user)
      else
        session[:omniauth] = omniauth.except('extra')
        redirect_to new_account_path
      end
    end
  end

  def destroy
    @authentication = current_user.authentications.find(params[:id])
    @authentication.destroy
    flash[:notice] = 'Successfully destroyed authentication.'
    redirect_to authentications_url
  end

  private
  def sign_in_and_redirect(user)
    unless current_user
      user_session = UserSession.new(User.find_by_single_access_token(user.single_access_token))
      user_session.save
    end
    redirect_back_or_default root_url
  end
end