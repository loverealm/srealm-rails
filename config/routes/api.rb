Rails.application.routes.draw do
  namespace :api, defaults: { format: 'json' } do
    get 'documentation' => redirect('/swagger/dist/index.html?url=/api/v1/documentations#/default')

    namespace :v2 do
      controller :public do
        post :send_feedback
      end
      namespace :pub do
        resources :user_credits, only: [:index] do
          collection do
            get :used_credits
            post :buy_credits
          end
        end
        resources :user_finances, only: [:index] do
          collection do
            get :tithe
            get :partner
            get :graphic
            get :pledges
            get :cards
          end
          member do
            get :show_payment
            post :stop_recurring
            delete :delete_card
            post :redeem_pledge
            post :update_pledge
            delete :delete_pledge
            post :update_recurring
            put :make_card_default
          end
        end
        resources :search, only: [:index] do
          get :google_place_info, on: :collection
          get :churches, on: :collection
        end
        resources :conversations, only: [:show, :index] do
          collection do
            post :create_group
            post :start_conversation
            get :public_groups
            get :suggested_mentor_conversation
          end
          member do
            get :unread_message_count
            get :read_messages
            get :messages
            get :participants
            post :start_typing
            post :stop_typing
            post :update_group
            post :join_conversation
            post :leave_conversation
            delete :destroy_group
            get :join
            scope ':user_id' do
              delete :ban_member
            end
          end
          resources :messages, only: [:create, :destroy] do
            post :create_multiple, on: :collection
          end
        end
        resources :notifications, only: :index do
          collection do
            get :unread_count
          end
        end
        resources :contents, only: [:show] do
          collection do
            post :create_status
            post :create_pray
            post :create_media
            post :create_question
            post :create_live_video
            post :get_praying_recommended_users
            get :widget_popular_content
            
            get :trending_now
            get :prepare_live_video
            get :my_praying_requests
            get :my_praying_feeds
            get :my_answered_prayers
            get :my_praying_feeds_of_others
          end
          member do
            get :stop_live_video
            post :update_live_video
            post :update_status
            post :update_pray
            post :update_media
            post :update_question
            post :add_prayers
            post :add_people_answer_question
            get :prayer_reject
            get :prayer_accept
            get :stop_praying
            get :likes
            post :answer_pray
            post :answer_pray_share
            post :share
            get :suggested_videos
            delete :stop_sharing
            scope ':file_id' do
              get :content_file_visit
            end
          end
        end
        resources :users, only: [] do
          collection do
            post :verify_new_user_data
            get :friends_birthday
            get :search_friends
            get :online_friends
            get :online_friends_qty
            get :deactivate_account
            get :toggle_anonymity
            get :suggested_preferences
            post :update_suggested_preferences
            post :update_phone_contacts
            get :church_counselors
            get :can_show_volunteer_invitation
            put :update_bio
            get :demographics
            get :countries
            scope ':user_id' do
              get :block_user
              get :unblock_user
            end
          end
        end
        resources :user_groups do
          member do
            get :send_request
            get :leave_group
            get :members
            get :counselors
            get :feed
            post :save_image
            post :add_members
            post :add_attendance
            post :make_default
            post :add_counselor
            delete :remove_counselor
            post :promote
            get :promotions
            get :member_requests
            get :members_birthday
            post :broadcast_message
            post :broadcast_sms
            put :confirm_broadcast_sms
            post :save_communion
            get :verify
            
            get :communion_members_data
            post :add_baptised_members
            get :baptised_members_data
            get :search_non_baptised_members
            get :search_non_baptised_members 
            get :baptised_members_data 
            post :add_baptised_members
            get :ask_communion 
            get :event_tickets_sold_data 
            get :communion_members_data
            post :new_manual_value
            post :invite_members
            get :attendances_data
            get :baptised_members
            
            get :total_payments_data
            get :new_members_data
            get :payment_data
            get :members_commonest_data
            get :members_sex_data
            get :age_of_members_data
            get :countries_of_members_data
            get :broadcast_report_data
            scope ':user_id' do
              delete :reject_member
              post :accept_request
            end
          end
          collection do
            get :default_church
            get :suggested_groups
            get :list
            get :type_list
            get :data
          end
          resources :meetings, controller: 'user_group_meetings', except: [:new, :edit] do
            member do
              get :non_attendances
              post :add_nonattendance
            end
          end
          resources :devotions, controller: 'user_group_devotions', except: [:new, :edit, :show]
          resources :member_invitations, controller: 'user_group_member_invitations', only: [:index, :create]
          resources :payments, controller: 'user_group_payments', only: [:index, :create] do
            collection do
              get :revenue_data
            end
          end
          resources :converts, controller: 'user_group_converts', only: [:create, :index] do
            get :search_new
            get :data
          end
          resources :files, controller: 'user_group_files', only: [:index, :destroy, :create]
          resources :events, controller: 'user_group_events', except: [:new, :edit] do
            get :promoted_events, on: :collection
            member do
              post :attend
              delete :no_attend
              post :buy_ticket
              post :promote
              get :promotions
              get :verify_ticket
              post :redeem_ticket
            end
          end
          resources :branches, controller: 'user_group_branches', only: [:index] do
            collection do
              post :sent_branch_request
              delete :cancel_branch_request
              put :accept_branch_request
              post :reject_branch_request
              delete :exclude_branch
              post :send_root_branch_request
              put :accept_root_branch_request
              post :reject_root_branch_request
              delete :cancel_root_branch_request
            end
          end
        end
        resources :bible, only: [] do
          collection do
            scope ':book_id/:chapter' do
              get :verses
            end
            get :books
            get 'passage/:book_id-:chapter::verse_numbers' => :passage, as: :passage
          end
        end
        resources :appointments, except: [:edit, :new] do
          member do
            get :reject
            get :accept
            get :start_call
            get :ping_call
            get :reject_call
            get :accept_call
            get :end_call
            post :re_schedule
            post :donation
          end
        end
      end
    end

    namespace :v1 do
      resources :documentations, only: :index do
        get :pub, on: :collection
      end

      namespace :mobile do
        get :dashboard, to: 'dashboard#show'
        get :mentor, to: 'mentor#show'
        get :search, to: 'search#index'
        get '/search/:type', to: 'search#by_type'
        resources :comments, only: [:create, :update]
        resources :hash_tags, only: :index do
          get :autocomplete_hash_tags, on: :collection
          get :preselected, on: :collection
        end
        resources :relationships, only: :create do
          post :follow, on: :collection
          post :unfollow, on: :collection
        end
        resources :statuses, only: [:create, :show, :update]
        resources :pictures, only: [:create, :show, :update]
        resources :videos, only: [:create, :show, :update] do
          put :show_count, on: :member
        end
        resources :stories, only: [:create, :show, :update]

        resources :users, only: [:create, :update] do
          get :meta_info, on: :member
          get :me, on: :collection
          get :profile, on: :member
          post :update_fcm_token, on: :member
          post :remove_fcm_token, on: :member
          put :cover, on: :member
          get :unread_message_count, on: :member
          get :following, on: :collection
          get :followers, on: :collection
          get :search_following, on: :collection
          resources :appointments, only: [:create]
          resources :hash_tags, controller: 'user_hash_tags', only: [:index, :create]
          post :password, to: 'passwords#create', on: :collection
          put :password, to: 'passwords#update', on: :collection
        end
        resources :suggested_users, only: :index
        resources :reports, only: :create
        resources :conversations, only: [:show, :index] do
          get :unread_message_count, on: :member
          get :read_messages, on: :member
          post :start_typing, on: :member
          post :stop_typing, on: :member
        end
        resources :notifications, only: :index
        resources :messages, only: [:create, :destroy] do
          collection do
            get :deleted
          end
        end
        resources :contents, only: [:index, :destroy] do
          get :get_answer_recommended_users, on: :collection
          member do
            post :like
            post :dislike
          end
        end
        resources :invitations, only: :create
        resources :shares, only: :create do
          delete '/', to: 'shares#destroy', on: :collection
        end
      end

      namespace :pub do
        get :dashboard, to: 'dashboard#show'
        controller :dashboard do
          get :app_version
          get :today_devotion
          get :today_greetings
          get :online_users
          get :settings
          scope ':mode' do
            put :switch_background_mode
          end
        end
        resources :mentors, controller: :mentor, only: [:index] do
          member do
            get :set_default
          end
          collection do
            get :my_revenue
            get :my_full_revenue
            get :my_counselor
            get :my_church_counselors
            get :search
            get :counseling_chats
          end
        end
        get :mentor, to: 'mentor#show'
        get :search, to: 'search#index'
        get '/search/:type', to: 'search#by_type'
        resources :comments do
          post :toggle_like, on: :member
          resources :answers do
            post :toggle_like, on: :member
          end
        end
        resources :hash_tags, only: :index do
          get :autocomplete_hash_tags, on: :collection
          get :trending_now, on: :collection
          get :preselected, on: :collection
        end
        resources :relationships, only: :create do
          post :follow, on: :collection
          post :unfollow, on: :collection
        end
        resources :statuses, only: [:create, :show, :update]
        resources :questions, only: [:create, :show, :update]
        resources :stories, only: [:create, :show, :update]
        resources :pictures, only: [:create, :show, :update]
        resources :videos, only: [:create, :show, :update] do
          put :show_count, on: :member
        end
        resources :users, only: [:create, :update] do
          get :meta_info, on: :member
          get :me, on: :collection
          get :profile, on: :member
          post :update_fcm_token, on: :member
          post :remove_fcm_token, on: :member
          put :cover, on: :member
          get :unread_message_count, on: :member
          collection do
            scope ':file_id' do
              delete :delete_photo
            end
            delete :delete_account
            get :following
            get :followers
            get :search_following
            get :friends
            get :pending_friends
            get :suggested_friends
            scope ':user_id' do
              post :ignore_suggested_friend
              post :send_friend_request
              post :cancel_friend
              post :cancel_friend_request
              post :reject_friend
              post :accept_friend
            end
          end
          get :bot_data
          post :bot_data_save
          resources :appointments, only: [:create]
          resources :hash_tags, controller: 'user_hash_tags', only: [:index, :create]
          post :password, to: 'passwords#create', on: :collection
          put :password, to: 'passwords#update', on: :collection
        end
        resources :suggested_users, only: :index
        resources :reports, only: :create
        resources :conversations, only: [:show, :index] do
          get :unread_message_count, on: :member
          get :read_messages, on: :member
          post :start_typing, on: :member
          post :stop_typing, on: :member
          post :create_group, on: :collection
          post :start_conversation, on: :collection
          post :update_group, on: :member
          post :join_conversation, on: :member
          post :leave_conversation, on: :member
          delete :destroy_group, on: :member
        end
        resources :notifications, only: :index
        resources :messages, only: [:create, :destroy] do
          collection do
            get :deleted
          end
        end
        resources :contents, only: [:index, :destroy] do
          match :get_answer_recommended_users, on: :collection, via: [:get, :post]
          get :live_board, on: :collection
          member do
            post :like
            post :dislike
          end
        end
        resources :invitations, only: :create
        resources :shares, only: :create do
          delete '/', to: 'shares#destroy', on: :collection
        end
      end

      namespace :web do
        resources :hash_tags, only: :index do
          get :autocomplete_hash_tags, on: :collection
        end
      end
    end
  end
end