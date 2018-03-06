class AddMissingIndexes < ActiveRecord::Migration
  def change
    add_index :bootsy_images, :image_gallery_id
    
    add_index :shares, [:content_id, :user_id]
    
    add_index :contents, :user_id
    add_index :contents, :owner_id
    add_index :contents, :content_type
    add_index :contents, :last_activity_time
    
    add_index :bot_questions, :bot_scenario_id
    
    add_index :comments, :content_id
    add_index :comments, :user_id
    
    add_index :bootsy_image_galleries, :bootsy_resource_id
    add_index :bootsy_image_galleries, :bootsy_resource_type
    
    add_index :recommends, :content_id
    add_index :recommends, :user_id
    add_index :recommends, :sender_id
    
    add_index :messages, :conversation_id
    add_index :messages, :receiver_id
    add_index :messages, :sender_id
    add_index :messages, :story_id
    
    add_index :hash_tags, :mentor_id
    
    add_index :mentions, :user_id
    add_index :mentions, :comment_id
    add_index :mentions, :content_id
    
    add_index :content_files, :content_id
    add_index :content_files, :tmp_key
    
    add_index :phone_number_invitations, :user_id
    
    add_index :counselor_reports, :user_id
    add_index :counselor_reports, :mentorship_id
    
    add_index :reports, [:target_id, :target_type]
    add_index :reports, :user_id
    
    add_index :conversations, :appointment_id
  end
end
