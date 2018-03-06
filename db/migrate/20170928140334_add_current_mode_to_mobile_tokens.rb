class AddCurrentModeToMobileTokens < ActiveRecord::Migration
  def change
    add_column :mobile_tokens, :current_mode, :string, default: 'foreground'
  end
end