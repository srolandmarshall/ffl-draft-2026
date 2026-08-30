Rails.application.routes.draw do
  root "home#index"

  resource :session, only: %i[new create destroy] do
    get :verify
    post :verify, action: :confirm
    post :resend_login_code
  end

  resources :drafts, only: :show, param: :public_id do
    get :players, on: :member
    resources :picks, only: %i[create destroy]
    resource :pick_timer, only: :update
    resource :export, only: :show
  end

  get "league/:id/history", to: "league_histories#show", as: :league_history
  get "league/:id/story", to: "league_stories#show", as: :league_story

  namespace :mcp do
    resources :leagues, only: %i[index show] do
      member do
        get :history
        get :standings
        get :matchups
        get :records
        get :player_scores
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

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
