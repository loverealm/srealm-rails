class AddGreetingSettings < ActiveRecord::Migration
  def change
    Setting.create(key: 'happy_birthday_art', image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'happy_birthday.gif').to_s))
    
    Setting.create(key: 'daily_inspiration_label', value: 'Today\'s Daily Inspiration is Titled - "%{title}"')
    Setting.create(key: 'happy_birthday_label', value: 'Happy Birthday! %{name}')
    
    Setting.create(key: 'good_morning_art', image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'morning.png').to_s))
    Setting.create(key: 'good_afternoon_art', image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'afternoon.png').to_s))
    Setting.create(key: 'good_night_art', image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'evening.png').to_s))
    
    Setting.create(key: 'good_morning_label', value: 'Good morning, %{name}')
    Setting.create(key: 'good_afternoon_label', value: 'Good afternoon, %{name}')
    Setting.create(key: 'good_night_label', value: 'Good evening, %{name}')
  end
end
