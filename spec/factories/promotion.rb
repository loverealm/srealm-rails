FactoryGirl.define do
  factory :promotion, class: Promotion do
    age_from 18
    age_to 99
    budget 21
    period_until { 2.months.from_now.to_date }
    factory :promotion_group, class: Promotion do
      website 'https://stackoverflow.com'
    end
  end
end
