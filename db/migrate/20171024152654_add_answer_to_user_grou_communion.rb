class AddAnswerToUserGrouCommunion < ActiveRecord::Migration
  def change
    add_column :user_group_communions, :answer, :boolean
  end
end
