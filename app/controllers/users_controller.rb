class UsersController < ApplicationController
  before_filter :require_user, :only => [:show, :edit, :update, :games, :invitations, :friend, :confirm_friend, :unfriend, :confirm_unfriend, :block, :confirm_block, :unblock, :confirm_unblock]
  before_filter :require_no_user, :only => [:new, :create, :confirm]
  before_filter :store_location, :except => [:new, :create, :resend_confirmation, :confirm]

  def friend
    @user = User.find(params[:id])
    deny_access unless @user.can_friend?(current_user)

    @friend = Friend.new(:user_id => current_user.id, :friend_user_id => @user.id)

    respond_to do |format|
      if @friend.save
        flash.now[:success] = 'You are now friends with ' + @user.login + '!'
      end
      format.js { render :layout => false }
      format.html { redirect_back_or_default root_url }
      format.xml { render :xml => friend }
    end
  end

  def confirm_friend
    deny_access unless @user.can_friend?(current_user)
  end

  def unfriend
    @user = User.find(params[:id])
    deny_access unless @user.can_unfriend?(current_user)

    @friend = Friend.where(:user_id => current_user.id, :friend_user_id => @user.id).first

    respond_to do |format|
      if @friend.destroy
        flash.now[:success] = 'You are no longer friends with ' + @user.login + '!'
      end
      format.js { render :layout => false }
      format.html { redirect_back_or_default root_url }
      format.xml { render :xml => friend }
    end
  end

  def confirm_unfriend
    deny_access unless @user.can_unfriend?(current_user)
  end

  def block
    @user = User.find(params[:id])
    deny_access unless @user.can_block?(current_user)

    @block = Block.new(:user_id => current_user.id, :blocked_user_id => @user.id)

    respond_to do |format|
      if @block.save
        flash.now[:success] = 'You have now blocked ' + @user.login + '!'
      end
      format.js { render :layout => false }
      format.html { redirect_back_or_default root_url }
      format.xml { render :xml => friend }
    end
  end

  def confirm_block
    deny_access unless @user.can_block?(current_user)
  end

  def unblock
    @user = User.find(params[:id])
    deny_access unless @user.can_unblock?(current_user)

    @block = Block.where(:user_id => current_user.id, :blocked_user_id => @user.id).first

    respond_to do |format|
      if @block.destroy
        flash.now[:success] = 'You are no longer blocking ' + @user.login + '!'
      end
      format.js { render :layout => false }
      format.html { redirect_back_or_default root_url }
      format.xml { render :xml => friend }
    end
  end

  def confirm_unblock
    deny_access unless @user.can_unblock?(current_user)
  end

  def games
    deny_access unless User.can_games?(current_user)
    @invitations = current_user.received_invitations.alive.order{ created_at.desc }.page(params["invitations_page"]).per(10)
    @pending_games = current_user.games.where{ended_at == nil}.with_friend_count(current_user).order('play_count desc').order('started_at IS NULL').order{ started_at.desc }.order{ created_at.desc }.page(params["pending_page"]).per(10)
    @finished_games = current_user.games.where{ended_at != nil}.with_friend_count(current_user).order{ ended_at.desc }.page(params["finished_page"]).per(10)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @games }
    end
  end

  def index
    deny_access unless User.can_index?(current_user)
    @users = User.can_index(current_user).all

    respond_to do |format|
      format.html
      format.xml  { render :xml => @users }
    end
  end

  def show
    if params[:id]
      @user = User.find(params[:id])
    else
      @user = current_user
    end

    deny_access unless @user.can_show?(current_user)

    respond_to do |format|
      format.html
      format.xml { render :xml => @user }
    end
  end

  def new
    deny_access unless User.can_new?(current_user)

    @user = User.new

    respond_to do |format|
      format.html
      format.xml { render :xml => @user }
    end
  end

  def edit
    @user = current_user
    deny_access unless @user.can_edit?(current_user)
  end

  def create
    deny_access unless User.can_create?(current_user)
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        Notifier.email_confirmation_instructions(@user).deliver
        flash.now[:notice] = 'A confirmation email has been sent to your email address. You will not be able to log in until you confirm your email address.'
        format.html {
          flash[:notice] =  flash.now[:notice]
          flash[:mail] =  flash.now[:mail]
          redirect_to root_url
        }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        flash.now[:failure] = 'Failed to create account.'
        format.html { render :action => 'new' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def confirm
    @user = User.find_using_perishable_token(params[:confirmation_code], 1.week)

    respond_to do |format|
      if !@user
        flash.now[:failure] = 'Email confirmation token invalid.'
        @user = User.new
        format.html { render :action => 'new' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      elsif @user.confirmed?
        flash.now[:failure] = 'Your email address has already been confirmed. You may log in.'
        format.html {
          flash[:failure] = flash.now[:failure]
          redirect_to root_url
        }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      else
        @user.confirm
        if @user.save
          UserSession.create(@user, false)
          Notifier.welcome(@user).deliver
          flash.now[:success] = 'Your email address has been confirmed!'
          format.html {
            flash[:success] =  flash.now[:success]
            flash[:mail] =  flash.now[:mail]
            redirect_to root_url
          }
          format.xml  { head :ok }
        else
          flash.now[:failure] = 'Email confirmation failed.'
          format.html { render :action => 'new' }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def resend_confirmation
    if params[:login]
      @user = User.find_by_smart_case_login_field params[:login]
      respond_to do |format|
        if @user && !@user.confirmed?
          Notifier.email_confirmation_instructions(@user).deliver
          flash.now[:notice] = 'Your confirmation email has been re-sent.'
          format.html {
            flash[:notice] =  flash.now[:notice]
            flash[:mail] =  flash.now[:mail]
            redirect_to root_url
          }
          format.xml  { head :ok }
        else
          flash.now[:failure] = 'Your email address has already been confirmed. You may log in.'
          format.html {
            flash[:failure] = flash.now[:failure]
            redirect_to root_url
          }
          format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  def update
    @user = current_user
    deny_access unless @user.can_update?(current_user)

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:success] = 'Your profile has been saved.'
        format.html { redirect_to @user }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  def delete
    @user = current_user

    deny_access unless @user.can_delete?(current_user)

    respond_to do |format|
      format.html
      format.xml { render :xml => @user }
    end
  end

  def destroy
    @user = current_user
    deny_access unless @user.can_destroy?(current_user)

    @user.deactivate

    respond_to do |format|
      if @user.save
        flash[:success] = 'Your account has been deleted.'
        format.html { redirect_to(root_url) }
        format.xml  { head :ok }
      else
        flash[:failure] = 'Failed to delete account.'
        format.html { render :action => 'delete' }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end
end

