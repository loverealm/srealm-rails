class AddWebsiteToPromotion < ActiveRecord::Migration
  def change
    add_column :promotions, :website, :string
  end
end
