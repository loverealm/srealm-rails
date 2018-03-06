class AddContentPrivacityLevel < ActiveRecord::Migration
  def change
    add_column :contents, :privacy_level, :string, default: 'public'
  end
end