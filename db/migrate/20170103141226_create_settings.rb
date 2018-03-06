class CreateSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.string :key
      t.text :value

      t.timestamps null: false
    end
    Setting.create(key: 'app_version', value: '1.0')
  end
end
