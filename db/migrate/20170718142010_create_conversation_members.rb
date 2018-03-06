class CreateConversationMembers < ActiveRecord::Migration
  def change
    create_table :conversation_members do |t|
      t.belongs_to :user, index: true
      t.boolean :is_admin, default: false
      t.belongs_to :conversation, index: true
      t.datetime :last_seen, default: "now()"
      t.timestamps null: false
    end
    
    Conversation.unscoped.all.find_each do |conversation|
      User.unscoped.where(id: conversation.participants).pluck(:id).each do |_id|
        record = conversation.conversation_members.new(user_id: _id, is_admin: conversation.admin_ids.include?(_id), created_at: Time.current, updated_at: Time.current)
        sql = record.class.arel_table.create_insert.tap { |im| im.insert(record.send(:arel_attributes_with_values_for_create, record.attribute_names)) }.to_sql
        execute sql
      end
    end

    # destroy single conversations with no other member
    Conversation.unscoped.singles.joins(:conversation_members).select('conversations.*').group('conversations.id').having('count(conversation_members.id) < 2').each do |conv|
      conv.destroy!
    end
  end
end
