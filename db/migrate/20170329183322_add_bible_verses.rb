class AddBibleVerses < ActiveRecord::Migration
  def change
    create_table :verses do |t|
      t.integer :book_num
      t.string :book_id, index: true
      t.string :book
      t.integer :chapter
      t.integer :verse, index: true
      t.text :text
      t.integer :translation_id, index: true
    end
    ActiveRecord::Base.connection.execute(IO.read(Rails.root.join('db/verses.sql').to_s))
  end
end
