class AddHashNameToUsers < ActiveRecord::Migration
  def change
    add_column :users, :mention_key, :string, index: true
    User.all.find_each do |user|
      user.generate_mention_key
    end

    create_table :mentions do |t|
      t.belongs_to :user
      t.belongs_to :comment
      t.belongs_to :content
      t.timestamps
    end
  end
end
