class CreateChurchBranches < ActiveRecord::Migration
  def change
    create_table :church_branches do |t|
      t.string :title
      t.text :descr
      t.belongs_to :user_group, index: true

      t.timestamps null: false
    end
    add_foreign_key :church_branches, :user_groups
  end
end
