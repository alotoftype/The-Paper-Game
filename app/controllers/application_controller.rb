class ApplicationController < ActionController::Base
  include ApplicationHelper
  require "exceptions"
  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::RoutingError, :with => :render_not_found
  rescue_from Exceptions::UnauthorizedError, :with => :render_unauthorized

  protect_from_forgery

  helper_method :current_user_session, :current_user

  protected
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.user
    end

    def deny_access
      raise Exceptions::UnauthorizedError.new('You do not have permissions to view the requested page.')
    end

    def render_not_found(exception = nil)
      if exception
          logger.info "Rendering 404: #{exception.message}"
      end

      render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
    end

    def render_unauthorized(exception = nil)
      if current_user
        render :template => 'pages/401', :status => :unauthorized
      else
        @user_session = UserSession.new
        respond_to do |format|
          flash.now[:failure] = 'You need to be logged in to view this page.'
          format.html { render :template => 'user_sessions/new', :status => :unauthorized }
          format.js   { render :template => 'user_sessions/failed', :layout => false }
        end
      end
    end

  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end

    def require_user
      unless current_user
        store_logged_in_location
        flash[:error] = 'You must be logged in to access this page.'
        respond_to do |format|
          format.html { redirect_to login_url }
          format.xml  { head :unauthorized }
        end
        return false
      end
    end

    def require_no_user
      if current_user
        store_logged_out_location
        flash[:error] = 'You must be logged out to access that page.'
        respond_to do |format|
          format.html { redirect_to back_or_default_path(root_url) }
          format.xml  { head :unauthorized }
        end
        return false
      end
    end

    def store_location
      if request.format.html?
        session[:return_to] = request.fullpath
        session[:return_to_logged_in] = nil
        session[:return_to_logged_out] = nil
      end
    end

    def store_logged_in_location
      session[:return_to_logged_in] = request.url
    end

    def store_logged_out_location
      session[:return_to_logged_out] = request.url
    end

    def redirect_back_or_default(default)
      redirect_to(back_or_default_path(default))
      session[:return_to] = nil
      session[:return_to_logged_in] = nil
      session[:return_to_logged_out] = nil
    end

    def verified_request?
      !protect_against_forgery? || request.get? ||
        params[request_forgery_protection_token] && form_authenticity_token == params[request_forgery_protection_token].gsub(' ', '+') ||
        form_authenticity_token == request.headers['X-CSRF-Token']
    end
end

