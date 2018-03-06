class Word < ActiveRecord::Base
  paginates_per 50
  after_save :clear_cache
  before_save :downcase_word
  
  def self.create_form_list(list_of_words)
    list_of_words.split("\n").map do |word|
      word.strip!
      Word.find_or_create_by name: word
    end
  end
  
  # return all bad words registered on the server
  def self.all_words
    Rails.cache.fetch('cache_bad_words_all_words') do
      Word.all.pluck(:name)
    end
  end
  
  private
  # remove saved bad words cache
  def clear_cache
    Rails.cache.delete('cache_bad_words_all_words')
  end
  
  # fix word case
  def downcase_word
    self.name = name.to_s.downcase
  end
end
