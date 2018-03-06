class FixDuplicatedHashTags < ActiveRecord::Migration
  def change
    # prepend # to all hashtags
    HashTag.all.find_each do |tag|
      name = tag.name.to_s.strip
      name = "##{name}" unless name.start_with? '#'
      tag.update_column(:name, name)
    end

    HashTag.where(name: ['#', '']).update_all(name: '#loverealm') # empty hash tag into loverealm
    
    HashTag.select(:name).group(:name).having("count(*) > 1").each do |_tag|
      tags = HashTag.search_by_name(_tag.name).to_a.map{|t| t.id }
      main_tag = tags.shift
      ContentsHashTag.where(hash_tag_id: tags).update_all(hash_tag_id: main_tag)
      HashTagsUser.where(hash_tag_id: tags).update_all(hash_tag_id: main_tag)
      Mentorship.where(hash_tag_id: tags).update_all(hash_tag_id: main_tag)
      HashTag.where(id: tags).delete_all
    end
  end
end