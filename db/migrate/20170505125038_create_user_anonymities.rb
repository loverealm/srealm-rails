class CreateUserAnonymities < ActiveRecord::Migration
  def change
    create_table :user_anonymities do |t|
      t.timestamp :start_time
      t.timestamp :end_time
      t.belongs_to :user , index: true
    end
  end
end