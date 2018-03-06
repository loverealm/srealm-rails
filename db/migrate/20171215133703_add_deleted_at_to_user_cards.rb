class AddDeletedAtToUserCards < ActiveRecord::Migration
  def change
    add_column :payment_cards, :deleted_at, :datetime, index: true
  end
end
