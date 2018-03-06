class UpdateGreetingGifts < ActiveRecord::Migration
  def change
    Setting.where(key: 'welcome_art').first.update(image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'gif', 'welcome_opt.gif').to_s))
    Setting.where(key: 'happy_birthday_art').first.update(image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'gif', 'birthday_opt.gif').to_s))
    Setting.where(key: 'good_night_art').first.update(image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'gif', 'evening_opt.gif').to_s))
    Setting.where(key: 'good_afternoon_art').first.update(image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'gif', 'afternoon_opt.gif').to_s))
    Setting.where(key: 'good_morning_art').first.update(image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'gif', 'morning_opt.gif').to_s))
  end
end
