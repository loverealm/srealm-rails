Rails.application.routes.draw do
  use_doorkeeper
  # resources :hash_tags, format: :json
  resources :reports
  # get '/invites/:provider/contact_callback' => "invites#contacts_callback"

  # get "/contacts/failure" => "invites#failure"
  # root :to => "invites#index"
  # resources :friends, only: [:index] do
  #   post 'fb_friends', on: :collection
  # end

  resources :feedbacks, only: [:create]

  devise_for :users, controllers: { registrations: 'registrations', omniauth_callbacks: 'omniauth_callbacks' }

  root to: 'home#index'
  get 'home/login', to: 'home#login', as: 'login'
  get 'home/about_us', to: 'home#about_us', as: 'about_us'
  get 'home/about_jesus', to: 'home#about_jesus', as: 'about_jesus'
  get 'home/careers', to: 'home#careers', as: 'careers'
  get 'home/privacy_policy', to: 'home#privacy_policy', as: 'privacy_policy'
  get 'home/terms', to: 'home#terms', as: 'terms'
  get 'home/help', to: 'home#help', as: 'help_new'
  get 'home/press', to: 'home#press', as: 'press_new'
  get 'home/feedback', to: 'home#feedback', as: 'feedback'
  get 'home/beta_notification', to: 'home#beta_notification', as: 'beta_notification', path: '/notification'
  get 'promo/mobile_app', to: 'home#mobile_app'
  get 'dl', to: 'home#dl'
  controller :home do
    get :badges
    get :mark_shown_invite_friends
    match 'opentok/callback/:token' => :opentok_callback, via: [:get, :post]
  end
end
