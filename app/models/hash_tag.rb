class HashTag < ActiveRecord::Base
  has_and_belongs_to_many :users
  has_and_belongs_to_many :contents

  has_many :mentorships
  has_many :mentors, class_name: 'User', through: :mentorships
  before_create :fix_prefix
  validates_presence_of :name
  
  class << self
    
    # exclude tags from current filtering
    def exclude(names)
      names = names.map do |n|
        "#{'#' unless n.start_with?('#')}#{n.strip}"
      end
      where.not(name: names)
    end
    
    def trending_tags(limit = nil)
      Rails.cache.fetch('trending_tags', expires_in: 1.day) {
        content_query = select('hash_tags.id, count(*) as weight')
                            .joins(:contents).group('hash_tags.id').to_sql

        select('hash_tags.*, SUM(trending_tags.weight) as total_weight')
            .from("(#{content_query}) AS trending_tags")
            .joins('INNER JOIN hash_tags ON hash_tags.id = trending_tags.id')
            .group('hash_tags.id').order(updated_at: :DESC).order('total_weight DESC').limit(limit || 16).to_a
      }
    end

    def get_tag(_name)
      tag = find_by_name(_name)
      tag = create!(name: _name) unless tag.present?
      tag
    end

    def find_by_name(_name)
      search_by_name(_name).first
    end

    def search_by_name(_name)
      _name = _name.to_s.strip.downcase
      _name = "##{_name}" unless _name.start_with? '#'
      where_ignore_case(name: _name)
    end

    # function to search hash tags by name (used in main search typeahead autocomplete)
    def search(query)
      where('LOWER(name) like ?', "%#{query}%")
    end
  end
  
  private
  def fix_prefix
    self.name = name.strip
    self.name = "##{name}" unless name.to_s.start_with?('#')
  end
end
