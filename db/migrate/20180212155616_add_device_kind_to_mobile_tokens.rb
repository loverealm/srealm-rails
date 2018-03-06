class AddDeviceKindToMobileTokens < ActiveRecord::Migration
  def change
    add_column :mobile_tokens, :kind, :string, default: 'android'
  end
end
