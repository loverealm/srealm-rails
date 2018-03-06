class CreateUserGroupManualValues < ActiveRecord::Migration
  def change
    create_table :user_group_manual_values do |t|
      t.belongs_to :user_group, index: true
      t.integer :value
      t.date :date
      t.string :kind, index: true
      t.timestamps null: false
    end
    add_foreign_key :user_group_manual_values, :user_groups
  end
end
