Rails.application.routes.draw do
  root "home#index"

  resource :session, only: %i[new create destroy] do
    get :verify
    post :verify, action: :confirm
    post :resend_login_code
  end

  get "/.well-known/oauth-protected-resource", to: "mcp/base#protected_resource_metadata",
    as: :mcp_protected_resource_metadata
  get "/.well-known/oauth-protected-resource/mcp", to: "mcp/base#protected_resource_metadata"
  get "/.well-known/oauth-authorization-server", to: "sessions#oauth_metadata",
    as: :oauth_authorization_server_metadata
  get "/oauth/authorize", to: "sessions#oauth_authorize", as: :oauth_authorize
  post "/oauth/authorize", to: "sessions#oauth_approve"
  post "/oauth/register", to: "sessions#oauth_register", as: :oauth_register
  post "/oauth/token", to: "sessions#oauth_token", as: :oauth_token
  post "/mcp", to: "mcp/base#handle", as: :mcp_server

  resources :drafts, only: :show, param: :public_id do
    get :players, on: :member
    resources :picks, only: %i[create destroy]
    resource :pick_timer, only: :update
    resource :export, only: :show
  end

  get "league/:id/history", to: "league_histories#show", as: :league_history

  namespace :mcp do
    resources :leagues, only: %i[index show] do
      member do
        get :history
        get :standings
        get :matchups
        get :records
        get :player_scores
        get :lineups
      end
    end
    resources :drafts, only: :show, param: :public_id do
      get :results, on: :member
      get :players, on: :member
    end
  end

  namespace :admin do
    root "dashboard#show"
    resources :leagues do
      patch :team_order, on: :member
      resource :espn_settings_sync, only: :create
      resource :espn_historical_score_sync, only: :create
      resource :espn_franchise_backfill, only: :create
      resource :espn_connection, only: %i[new create destroy]
      resources :teams, except: :show do
        member { patch :archive; patch :unarchive }
      end
      resources :drafts, except: :show do
        member { patch :start; patch :restart; patch :auto_draft; post :broadcast_message }
      end
    end
    resources :players, except: :show
    resources :users, only: %i[index update]
    resource :player_import, only: %i[new create]
    resource :ranking_import, only: %i[new create]
    resource :espn_player_sync, only: :create
    resource :nflverse_player_sync, only: :create
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
