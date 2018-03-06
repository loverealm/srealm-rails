class CreateSuggestedUsers < ActiveRecord::Migration
  def change
    create_table :suggested_users do |t|
      t.belongs_to :user, index: true
      t.string :kind, index: true
      t.references :suggestandable, polymorphic: true, index: {name: 'index_suggestandable_id_type'}
      t.timestamps null: false
    end
    add_column :banned_users, :kind, :string, index: true
  end
end
