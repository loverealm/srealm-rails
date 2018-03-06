Rails.application.routes.draw do
  get '/Majid' => redirect('/dashboard/users/13440/profile')
  get '/users/unsubscribe/:signature', to: 'application#unsubscribe', as: :unsubscribe
  namespace :dashboard do
    # post '/welcome_3/send_invitations', to: 'welcome#send_invitations', as: 'welcome_send_invitations'
    controller :welcome do
      get :finish_registration
      post :save_finish_registration
    end
    

    resources :comments, except: [:index] do
      post :toggle_vote, on: :member
      resources :answers, except: [:index] do
        post :toggle_vote, on: :member
      end
    end

    resources :search, only: [:index] do
      collection do
        get :get_users
        get :user_professions
        match :recommended_users, via: [:get, :post]
        get :get_online_users
        get :get_autocomplete_data
        get :google_place_info
      end
    end

    get 'contents/stories', to: 'contents#stories'
    resources :bible, only: [] do
      collection do
        scope ':book_id/:chapter' do
          get :verses
        end
        get :books
        get 'passage/:book_id-:chapter::verse_numbers' => :passage, as: :passage
      end
    end
    resources :invites, only: [:index, :create]
    resources :contents do
      collection do
        post :upload_image
        get :live_board
        get :new_live_video
        get :widget_popular_content
      end
      member do
        scope ':file_id' do
          get 'mark_file_visited'
        end
        get 'toogle_like'
        put 'update_picture'
        put 'update_video'
        get 'comments', to: 'comments#index'
        match :add_prayers, via: [:get, :post]
        get :prayer_reject
        get :prayer_accept
        get :stop_praying
        get :likes
        get :answer_pray
        post :answer_pray
        get :stop_live_video
        get :visit_live_video
        get :widget
      end
    end

    get 'users/:id/inbox', to: 'users#inbox', as: 'inbox'
    get 'users/:id/preferences', to: 'users#preferences', as: 'preferences'
    get 'users/:id/profile', to: 'users#profile', as: 'profile'
    resources :user_credits do
      collection do
        match :buy_credits, via: [:get, :post]
        get :used_credits
      end
    end
    resources :user_finances, only: [:index] do
      collection do
        get :tithe_partner
        get :graphic
        get :pledges
        get :donate_church
      end
      member do
        get :show_payment
        post :stop_recurring
        delete :delete_card
        match :redeem_pledge, via: [:get, :post]
        match :ask_pledge, via: [:get, :post]
        match :edit_recurring, via: [:get, :post]
        delete :delete_pledge
        put :make_card_default
      end
    end
    resources :users, only: [:show] do
      collection do
        get :continue_bot_questions
        delete :destroy_user_photo
        get :news_feed
        get :resend_confirmation_email
        
        post :update
        put :profile_avatar
        put :profile_cover

        get :following, action: :relationship, method: :following
        get :followers, action: :relationship, method: :followers

        get :my_praying_list
        get :my_praying_list_of_others
        get :my_praying_list_requests
        get :my_praying_list_answered
        
        match :information_edit, via: [:get, :post]
        match :my_preferences_edit, via: [:get, :post]
        
        delete :delete_account
        put :update_password
        get :suggested
        post :report_counselor
        get :pending_friends
        get :friends
        get :toggle_anonymity
        get :suggested_friends
        delete :deactivate_account
        scope ':user_id' do
          post :send_friend_request
          post :cancel_friend
          post :cancel_friend_request
          post :ignore_suggested_friend
          post :reject_friend
          post :accept_friend
          get :block_user
          get :unblock_user
          get :unfollow_user
          get :follow_user
          get :cancel_follow_suggestion
        end
      end

      # resources :appointments, only: [:create, :index] do
      #   member do
      #     get :reject
      #     get :accept
      #     match :re_schedule, via: [:get, :post]
      #   end
      # end
    end

    resources :counselors, only: [:index] do
      collection do
        get :my_revenue
        get :church_counselors
      end
      member do
        get :set_default
        get :video_counseling
        get :start_video
        get :make_payment
        post :make_payment
        scope ':video_id' do
          get :end_video
        end
      end
    end
    resources :appointments do
      member do
        get :reject
        get :accept
        get :start_call
        get :ping_call
        get :cancel_call
        get :reject_call
        get :accept_call
        get :end_call
        get :success_paypal
        match :re_schedule, via: [:get, :post]
        match :donation, via: [:get, :post]
      end
    end

    resources :user_groups do
      get :search, on: :collection
      member do
        get :send_request
        get :leave_group
        get :members
        get :payment_options
        get :about
        post :make_payment
        post :save_image
        get :try_donation
        get :success_paypal
        get :save_communion
        get :verify
        match :add_members, via: [:get, :post]
        scope ':file_id' do
          delete :destroy_photo
        end
        scope ':user_id' do
          post :accept_request
        end
      end
      resources :events, controller: 'church_events' do
        member do
          get :success_paypal
          match :buy, via: [:get, :post]
          match :attend, via: [:get, :post]
        end
        get :list, on: :collection
        resources :promotions, controller: 'church_event_promotions', except: [:destroy, :update] do
          match :pay, via: [:get, :post], on: :member
        end
      end
      collection do
        get :suggested_groups
      end
      resources :daily_devotions, controller: 'church_devotions'
      resources :promotions, controller: 'church_promotions', except: [:destroy, :update] do
        match :pay, via: [:get, :post], on: :member
      end
      resources :meetings, controller: 'church_meetings'
      resources :converts, controller: 'church_converts' do
        collection do
          get :search_new
          get :data
        end
      end
      resources :requests, controller: 'church_requests', only: [:new, :index] do
        collection do
          post :send_main
          get :cancel_main_branch
          scope ':id' do
            get :accept
            get :reject
            get :cancel
            get :exclude_branch
            
            get :accept_main
            get :reject_main
            get :cancel_main
          end
        end
      end
      resources :churches_management, path: 'admin', only: [:index] do
        collection do
          get :members
          get :countries_of_members_data
          get :age_of_members_data
          get :members_sex_data
          get :members_commonest_data
          get :payment_data
          get :new_members_data
          get :total_payments_data
          get :attendances_data
          get :event_tickets_sold_data
          match :invite_members, via: [:get, :post]
          match :new_manual_value, via: [:get, :post]
          
          get :grow_church
          get :grow_church_data
          match :edit_counselors, via: [:get, :post]
          match :broadcast_sms, via: [:get, :post]
          match :broadcast_message, via: [:get, :post]
          match :add_baptised_members, via: [:get, :post]
          match :broadcast_message_confirm_sms, via: [:get, :post]
          get :search_non_baptised_members
          get :baptised_members_data
          get :ask_communion
          get :communion_members_data
          get :broadcast_report_data
          match :new_members, via: [:get, :post]
          scope ':user_id' do
            put :accept_member
            delete :reject_member
            get :toggle_admin
            delete :delete_member
          end
          get :basic_info
          match :edit_info, via: [:get, :post]
          match :manual_payment, via: [:get, :post]
          post :upload_files
          get :pending_payments
          scope ':id' do
            get :send_tithe_reminder
            get :send_pledge_reminder
          end
        end
      end
    end
    resources :notifications, only: [:index]
    resources :conversations do
      member do
        get :show_group
        post :start_typing
        post :stop_typing
        post :join_conversation
        post :leave_conversation
        patch :update_group
        get :edit_group
        get :messages
        get :participants

        get :read_messages
        get :messages
        post :add_message
        scope ':message_id' do
          delete :remove_message
        end
        get :participants
        get :rendered_conversation
        get :mark_as_visited
        post :destroy_group
        scope ':user_id' do
          delete :del_member
          delete :ban_member
          post :toggle_admin
        end
      end

      collection do
        get :recent_messages
        get :online_friends
        get :tabs_information
        get :join
        get :list
        get  :search
        get :chat_list
        get :start_conversation
        get :suggested_mentor_conversation
        match :create_group, via: [:get, :post]
      end
    end

    resources :shares, only: :create do
      delete '/remove', to: 'shares#destroy_by_content_id', on: :collection
    end
  end
end
