class GamesController < ApplicationController
  before_filter :store_location, :except => [:create, :update, :join, :confirm_join, :start, :confirm_start, :destroy, :leave]
  before_filter :find_game, :only => [:start, :confirm_start, :join, :confirm_join, :show, :edit, :update, :destroy, :leave]
  before_filter :new_game_from_params, :only => [:create]
  before_filter :new_game, :only => [:new]
  before_filter :require_user, :only => [:new, :create, :update, :join, :start, :destroy, :leave]

  def index
    deny_access unless Game.can_index?(current_user)
    @search = Game.search(params[:q])
    @games = @search.result
    if (current_user)
      @games = @games.can_index(current_user)
    end
    @games = @games.
      with_friend_count(current_user).
      order('friend_count desc').page(params[:page]).per(15)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @games }
    end
  end

    def confirm_start
      deny_access unless @game.can_start?(current_user)
  end

  def start
    deny_access unless @game.can_start?(current_user)

    respond_to do |format|
      if @game.start
        flash[:success] = 'The game has begun!'
        # TODO: for each player, update round and pending play
        update_payer_lists(@game)
        format.html { redirect_to @game }
        format.xml  { render :xml => @player, :status => :created, :location => @player }
      else
        format.html { render :action => 'show' }
        format.xml  { render :xml => @player.errors, :status => :unprocessable_entity }
      end
    end
  end

  def join
    deny_access unless @game.can_join?(current_user)

    respond_to do |format|
      if @game.add_player(current_user)
        flash[:success] = 'You have joined this game.'
        update_payer_lists(@game)
        format.xml  { render :xml => @player, :status => :created, :location => @player }
      else
        flash[:failure] = @game.errors[:base].join(' ')
        format.xml  { render :xml => @player.errors, :status => :unprocessable_entity }
      end
      format.html { redirect_to @game }
    end
  end

  def confirm_join
    deny_access unless @game.can_join?(current_user)
  end

  def leave
    deny_access unless @game.can_leave?(current_user)
    @player = @game.player(current_user)

    respond_to do |format|
      if @player.leave!
        flash[:success] = 'You left the game.'
        update_payer_lists(@game)
        format.xml  { render :xml => @player, :status => :created, :location => @player }
      else
        flash[:failure] = @game.errors[:base].join(' ')
        format.xml  { render :xml => @player.errors, :status => :unprocessable_entity }
      end
      format.html { redirect_to @game }
    end
  end

  def confirm_leave
    deny_access unless @game.can_leave?(current_user)
  end

  def show
    deny_access unless @game.can_show?(current_user)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @game }
      format.css
    end
  end

  def new
    deny_access unless @game.can_new?(current_user)

    respond_to do |format|
      format.html
      format.xml  { render :xml => @game }
    end
  end

  def edit
    deny_access unless @game.can_edit?(current_user)
  end

  def create
    deny_access unless @game.can_create?(current_user)

    respond_to do |format|
      if @game.save
        flash[:success] = 'Game was successfully created.'
        format.html { redirect_to @game }
        format.xml  { render :xml => @game, :status => :created, :location => @game }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    deny_access unless @game.can_update?(current_user)

    respond_to do |format|
      if @game.update_attributes(params[:game])
         flash[:success] = 'Game was successfully updated.'
        format.html { redirect_to @game }
        format.xml  { head :ok }
      else
        format.html { render :action => 'edit' }
        format.xml  { render :xml => @game.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    deny_access unless @game.can_destroy?(current_user)
    @game.destroy

    respond_to do |format|
      format.html { redirect_to(games_url) }
      format.xml  { head :ok }
    end
  end

  private
  def find_game
    @game = Game.find(params[:id])
  end

  def new_game_from_params
    @game = Game.new(params[:game])
    @game.creator = current_user
  end

  def new_game
    @game = Game.new
  end
end

