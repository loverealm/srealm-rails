FactoryGirl.define do
  factory :conversation do
    owner
    factory :conversation_group do
      group_title Faker::FunnyName.name
      image { File.new("#{Rails.root}/spec/support/fixtures/rails.png")  }
      factory :conversation_private_group do
        is_private true
      end
    end
    
    factory :conversation_with_bot do
      with_bot true
    end
  end
end
