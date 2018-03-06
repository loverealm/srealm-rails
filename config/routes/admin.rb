Rails.application.routes.draw do
  namespace :admin do
    resources :counselor_reports, only: [:index, :destroy]
    resources :mentors
    resources :official_mentors
    resources :verified_groups, only: [:index] do
      get :search_unverified, on: :collection
      match :add_group, via: [:get, :post], on: :collection
      delete :unmark_verified, on: :member
    end
    resources :payments, only: [:index] do
      member do
        put :mark_as_transferred
        delete :unmark_transferred
      end
    end
    resources :verified_ads, only: [:index] do
      member do
        post :approve
        match :reject, via: [:get, :post]
      end
    end
    resources :mentor_categories do
      member do
        get :members
        match :add_members, via: [:get, :post]
        scope ':user_id' do
          delete :remove_member
        end
      end
    end
    resources :words
    resources :stories, only: [:index, :new, :create, :edit, :update]
    resources :home, only: [:index], path: 'dashboard' do
      get 'chart/:kind' => :chart, as: :chart, on: :collection
      get :send_christmas_newsletter, on: :collection
      get :bot, on: :collection
    end
    resources :logged_user_messages, only: [:index, :new, :create] do
      resources :bot_custom_answers
    end
    resources :reports, only: [:index, :show] do
      post :process_report, on: :member
      post :reviewed, on: :member
    end
    resources :users, only: [:index, :destroy] do
      collection do
        get :inactive
        get :banned
        get :verified
        post :save_verified
        get :promoted
        get :volunteers
        get :watchdogs
      end
      member do
        post :make_banned
        post :unban
        post :create_mentor
        post :make_promoted
        post :unmake_promoted
        post :make_volunteer
        delete :unmake_volunteer
        put :make_unverified
        post :make_watchdog
        delete :unmake_watchdog
      end
      post :unban, on: :member
      post :create_mentor, on: :member
    end
    resources :watchdog_actions, only: [:show, :index] do
      collection do
        get :marked_ban_users
        get :marked_prevent_posting_users
        get :marked_prevent_commenting_users
        get :marked_deleted_contents
        get :marked_deleted_comments
        scope ':kind' do
          get :search
        end
      end
      member do
        match :mark_ban_user, via: [:get, :post]
        match :mark_prevent_posting, via: [:get, :post]
        match :mark_prevent_commenting, via: [:get, :post]
        match :mark_deleted_content, via: [:get, :post]
        match :mark_deleted_comment, via: [:get, :post]

        match :revert_deleted_comment, via: [:get, :post]
        match :revert_deleted_content, via: [:get, :post]
        match :revert_prevent_commenting, via: [:get, :post]
        match :revert_prevent_posting, via: [:get, :post]
        match :revert_ban_user, via: [:get, :post]
        post :confirm
        get :toggle_mode
      end
    end
    resources :roles, only: [:index, :edit, :update]
    resources :feedbacks, only: [:index, :show]
    resources :settings, only: [:index] do
      post :save_settings, on: :collection
    end
    resources :marketings, only: [:index] do
      collection do
        post :send_email
        get :download_numbers
        post :send_message
      end
    end
    resources :break_news, only: [:new, :index, :create] do
      get :posts, on: :collection
    end
  end
end