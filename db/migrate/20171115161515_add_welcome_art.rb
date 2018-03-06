class AddWelcomeArt < ActiveRecord::Migration
  def change
    Setting.create(key: 'welcome_art', image: File.open(Rails.root.join('app', 'assets', 'images', 'greetings', 'welcome.gif').to_s))
    Setting.create(key: 'welcome_label', value: 'Welcome to LoveRealm')
  end
end
