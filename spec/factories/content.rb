FactoryGirl.define do
  factory :status, class: Content do
    description { Faker::Lorem.sentence }
    content_type 'status'
    user
  end

  factory :picture, class: Content do
    description { Faker::Lorem.sentence }
    content_type 'image'
    image { File.new(Rails.root.join('spec', 'support', 'fixtures', 'rails.png')) }
    user
  end

  factory :content_video, class: Content do
    description { Faker::Lorem.sentence }
    content_type 'video'
    video { File.new(Rails.root.join('spec', 'support', 'fixtures', 'ruby.mp4')) }
    user
  end

  factory :story, class: Content do
    description { Faker::Lorem.sentence }
    content_type 'story'
    image { File.new(Rails.root.join('spec', 'support', 'fixtures', 'rails.png')) }
    title { Faker::Lorem.sentence }
    user
  end
  
  factory :daily_story, class: Content, parent: :story do
    content_type 'daily_story'
    user
  end
  
end
