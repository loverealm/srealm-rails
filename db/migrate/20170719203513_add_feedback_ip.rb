class AddFeedbackIp < ActiveRecord::Migration
  def change
    add_column :feedbacks, :ip, :string
  end
end
