class CreateUserGroups < ActiveRecord::Migration
  def change
    create_table :user_groups do |t|
      t.attachment :image
      t.attachment :banner
      t.string :key, index: true, default: ''
      t.string :name
      t.text :description, default: ''
      t.string :kind, default: 'general', index: true
      t.string :privacy_level, default: 'open'
      t.integer :participant_ids, array: true, default: []
      t.integer :admin_ids, array: true, default: []
      t.integer :hashtag_ids, array: true, default: []
      t.integer :request_member_ids, array: true, default: []
      
      t.belongs_to :conversation, index: true
      t.belongs_to :user, index: true

      t.timestamps null: false
    end
    
    add_belongs_to :contents, :user_group, index: true
    
  end
end
