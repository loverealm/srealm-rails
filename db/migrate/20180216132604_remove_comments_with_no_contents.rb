class RemoveCommentsWithNoContents < ActiveRecord::Migration
  def change
    Comment.all.find_each do |c|
      c.destroy! unless c.content
    end
  end
end