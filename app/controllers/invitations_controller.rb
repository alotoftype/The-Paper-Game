class InvitationsController < ApplicationController
  before_filter :find_invitation, :only => [:accept, :decline]
  before_filter :new_invitation, :only => :new
  before_filter :new_invitation_from_params, :only => :create
  before_filter :store_location, :only => [:new]

  def accept
    deny_access unless @invitation.can_accept?(current_user)
    respond_to do |format|
      if @invitation.accept
        update_payer_lists(@invitation.game)
        flash[:success] = 'Invitation accepted.'
        format.html { redirect_to @invitation.game }
        format.xml  { render :xml => @invitation, :status => :created, :location => @invitation }
      else
        flash[:failure] = 'Invitation failed to accept.'
        format.html { redirect_back_or_default root_url }
        format.xml  { render :xml => @invitation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def decline
    deny_access unless @invitation.can_decline?(current_user)
    @invitation.has_accepted = false;
    respond_to do |format|
      if @invitation.save
        flash[:success] = 'Invitation declined.'
        format.html { redirect_back_or_default root_url }
        format.xml  { render :xml => @invitation, :status => :created, :location => @invitation }
      else
        flash[:failure] = 'Invitation failed to decline.'
        format.html { redirect_back_or_default root_url }
        format.xml  { render :xml => @invitation.errors, :status => :unprocessable_entity }
      end
    end
  end

  def new
    deny_access unless @invitation.can_new?(current_user)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @invitation }
    end
  end

  def create
    deny_access unless @invitation.can_create?(current_user)
    respond_to do |format|
      if @invitation.save
        flash[:success] = 'Invitation sent!'
        format.html { redirect_to @game }
        format.xml  { render :xml => @invitation, :status => :created, :location => @invitation }
      else
        flash.now[:failure] = 'Invitation failed to send.'
        format.html { render :action => 'new' }
        format.xml  { render :xml => @invitation.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def find_invitation
    @invitation = Invitation.find(params[:id])
  end

  def new_invitation
    @game = Game.find(params[:game_id])
    @invitation = @game.invitations.new
  end

  def new_invitation_from_params
    @game = Game.find(params[:game_id])
    @invitation = @game.invitations.new(params[:invitation])
    @invitation.inviter = current_user
  end
end

