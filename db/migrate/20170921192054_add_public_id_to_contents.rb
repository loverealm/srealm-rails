class AddPublicIdToContents < ActiveRecord::Migration
  def change
    add_column :contents, :public_uid, :string, index: true
    Content.where(public_uid: nil).find_each do |content|
      content.generate_uid
      content.update_column(:public_uid, content.public_uid)
    end
  end
end