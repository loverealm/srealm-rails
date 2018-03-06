class AddAcroosToMessages < ActiveRecord::Migration
  def change
    change_table :messages do |t|
      t.belongs_to :across_message, polymorphic: true
    end
  end
end
