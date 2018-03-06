class AddAnonymousAccount < ActiveRecord::Migration
  def change
    add_column :users, :roles, :integer, index: true

    pass = '/(UJQ%$JZVKIDU)/'
    User.create!(email: 'anonymous@loverealm.com', first_name: 'Anonymous', last_name: '.', confirmed_at: Time.now, password: pass, password_confirmation: pass)
  end
end
