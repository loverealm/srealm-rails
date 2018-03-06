class AddAttachmentVideoToContents < ActiveRecord::Migration
  def self.up
    change_table :contents do |t|
      t.attachment :video
    end
  end

  def self.down
    remove_attachment :contents, :video
  end
end
