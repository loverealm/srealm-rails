FactoryGirl.define do
  factory :appointment do
    schedule_for { rand(1..5).hours.from_now }
    kind 'video'
    factory :appointment_walkin do
      kind 'walk_in'
      location { Faker::Address.street_address }
    end
  end
end
