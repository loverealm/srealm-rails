include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :user_group do
    name {Faker::Name.name}
    description {Faker::Lorem.sentence}
    kind { UserGroup::KINDS.keys.sample }
    privacy_level { ['open', 'closed'].sample }
    user
  end
end