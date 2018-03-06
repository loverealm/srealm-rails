class CreateBroadcastMessages < ActiveRecord::Migration
  def change
    create_table :broadcast_messages do |t|
      t.attachment :custom_phones
      t.text :message
      t.string :from
      t.string :kind, default: 'normal'
      t.integer :branches, array: true, default: []
      t.string :age_range, default: '0,100'
      t.integer :gender
      t.string :countries, array: true, default: []
      t.belongs_to :user_group, index: true

      t.timestamps null: false
    end
  end
end
