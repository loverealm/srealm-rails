class AddGreetingColorSeetings < ActiveRecord::Migration
  def change
    Setting.create(key: 'good_morning_color', value: '#333333')
    Setting.create(key: 'good_afternoon_color', value: '#333333')
    Setting.create(key: 'good_night_color', value: '#333333')

    Setting.create(key: 'good_morning_color_title', value: '#333333')
    Setting.create(key: 'good_afternoon_color_title', value: '#333333')
    Setting.create(key: 'good_night_color_title', value: '#333333')
  end
end