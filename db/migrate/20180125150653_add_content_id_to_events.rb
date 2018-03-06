class AddContentIdToEvents < ActiveRecord::Migration
  def change
    add_belongs_to :events, :content, index: true
  end
end
