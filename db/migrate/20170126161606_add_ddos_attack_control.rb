class AddDdosAttackControl < ActiveRecord::Migration
  def change
    create_table :attack_requests do |t|
      t.string :path, index: true
      t.string :browser_key, index: true
      t.timestamps
    end
  end
end
