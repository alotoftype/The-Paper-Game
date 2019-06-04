Paper::Application.routes.draw do
  match 'login' => 'user_sessions#new'
  match 'logout' => 'user_sessions#destroy'

  resources :user_sessions, :only => [:new, :create, :destroy]

  resources :plays, :only => :create do
    #noinspection RailsParamDefResolve
    resource :star, :controller => 'play_stars', :only => [:create, :destroy]
  end

  resources :pictures, :only => :show

  resources :users, :only => [:index, :show, :create, :update] do
    member do
      post :friend
      get :friend, :action => :confirm_friend
      post :unfriend
      get :unfriend, :action => :confirm_unfriend
      post :block
      get :block, :action => :confirm_block
      post :unblock
      get :unblock, :action => :confirm_unblock
    end
  end

  #noinspection RailsParamDefResolve
  resource :account, :controller => 'users', :only => [:edit, :new, :show, :destroy] do
    member do
      get :games
      get :delete
      get 'resend_confirmation/:login', :action => 'resend_confirmation', :as => 'resend_confirmation'
      get 'confirm/:confirmation_code', :action => 'confirm', :as => 'confirm'
    end
    resource :login_reminder, :only => [:new, :create]
    resources :password_resets, :only => [:new, :create, :edit, :update]
  end

  resources :games do
    #noinspection RailsParamDefResolve
    resources :messages, :controller => 'game_messages', :only => [:create, :destroy]
    resources :sequences, :only => :show
    resources :players, :only => [] do
      member do
        post :eject
      end
    end
    resources :invitations, :only => [:new, :create], :shallow => true do
      member do
        post :accept
        post :decline
      end
    end
    resource :user_token, :controller => 'game_user_tokens', :only => [:show]
    member do
      post :join
      get :join, :action => :confirm_join
      post :leave
      get :leave, :action => :confirm_leave
      post :start
      get :start, :action => :confirm_start
      get :colors
    end
  end

  resources :players, :only => [] do
    resource :user_token, :controller => 'player_user_tokens', :only => [:show]
  end

  resources :pages, :only => [:show]
  
  resources :authentications, :only => [:create, :destroy]
  match '/auth/:provider/callback' => 'authentications#create'

  resource :notifications do
    get :send_daily_digest
  end

  root :to => 'pages#home'
  match 'example' => 'pages#example'
end