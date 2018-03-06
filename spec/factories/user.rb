include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :user, aliases: [:author, :owner] do
    email { Faker::Internet.email }
    password 'loverealm'
    password_confirmation 'loverealm'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    avatar_file_name { 'avatar' }
    is_newbie { false }
    biography { Faker::Lorem.sentence }
    confirmed_at Date.today
    notifications_checked_at Date.today
    
    factory :user_other_mentor do
      roles [:mentor]
    end
    factory :user_official_mentor do
      roles [:official_mentor]
    end
    
    transient do
      followers nil
    end

    # after(:create) do |model, evaluator|
    #   [*evaluator.followers].each do |follower|
    #     model.passive_relationships.create follower_id: follower.id, followed_id: model.id
    #   end
    # end
    
  end

  factory :user_with_content, class: User do
    email { Faker::Internet.email }
    password 'loverealm'
    password_confirmation 'loverealm'
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    avatar_file_name { 'avatar' }
    is_newbie { false }
    biography { Faker::Lorem.sentence }
    confirmed_at Date.today

    after(:create) do |user|
      user.contents << build(:status, user_id: user.id)
    end
  end

  factory :newbie_user, class: User do
    email { Faker::Internet.email }
    password 'loverealm'
    password_confirmation 'loverealm'
    confirmed_at Date.today
    is_newbie { true }
  end

  factory :admin, class: User do
    email { Faker::Internet.email }
    password 'loverealm'
    password_confirmation 'loverealm'
    confirmed_at Date.today
    roles [:admin]
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    biography { Faker::Lorem.sentence }
  end

  factory :bot, class: User do
    email { Faker::Internet.email }
    password 'loverealm'
    password_confirmation 'loverealm'
    confirmed_at Date.today
    roles [:bot]
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    biography { Faker::Lorem.sentence }
  end
end
