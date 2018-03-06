require 'sanitize'
class String
  attr_accessor :is_safe_string
  # Skip all dangerous html tags from current string
  # allowed_tags: string of accepted html tags concatenated with |
  # return string with valid html tags
  def strip_dangerous_html_tags(allowed_tags = 'a|span|strong|b|img|i|s|p|br|h1|h2|h3|h4|h5|h6|blockquote|footer', attributes = {'img' => ['src', 'alt'], 'a' => ['href', 'title', 'target']})
    if allowed_tags.present?
      Sanitize.fragment(self, {elements: allowed_tags.split('|'), attributes: attributes})
    else
      self.gsub('<', "&lt;").gsub('>', "&gt;")
    end
  end
  
  # mask all user mentions with link to each one
  # sample: Hi @owen-peredo ==> Hi <a href='....'>@owen-peredo</a>
  def mask_mentions
    res = self
    self.scan(/@[\w-]+/).flatten.uniq.each do |mention_key|
      res = res.gsub("#{mention_key}", "<a href='/dashboard/users/#{mention_key.sub('@', '')}/profile'>#{mention_key}</a>")
    end
    res
  end
  
  def mask_hashtags
    res = self
    self.scan(/#[\w-]+/).flatten.uniq.each do |hash_key|
      res = res.gsub("#{hash_key}", "<a href='/dashboard/contents/?tag_key=#{hash_key.sub('#', '')}'>#{hash_key}</a>")
    end
    res
  end
  
  # return all hash tags detected in current string
  def find_hash_tags
    self.scan(/#[\w-]+/).flatten.uniq
  end

  # convert skipped html characters
  def reverse_html_tags
    self.gsub('&lt;', "<").gsub('&gt;', ">")
  end
  
  # check if current text is a sticker code
  def is_sticker_code?
    self.scan(/^\[\[[0-9]{4,}\]\]$/).any?
  end
  
  # recursively replace values in current text 
  def recursive_gsub(search_txt, txt_to_replace)
    res = self
    res = res.gsub(search_txt, txt_to_replace).recursive_gsub(search_txt, txt_to_replace) if res.include?(search_txt)
    res
  end
  
  # check if string is a numeric or text 
  def is_i?
    /\A[-+]?\d+\z/ === self
  end
  
  # return range of the text period and also returns the kind of report: if daily => true, else false
  # sample: 'this_month'.report_period_to_range ==> [time_from..time_to, true]
  def report_period_to_range
    daily_report = false
    range = case self
            when 'this_month'
              daily_report = true
              (Date.today.beginning_of_month..Date.today)
            when 'last_month'
              daily_report = true
              (1.month.ago.to_date.beginning_of_month..1.month.ago.to_date.end_of_month)
            when 'last_6_months'
              (5.months.ago.to_date.beginning_of_month..Date.today).select {|d| d.day == 1}
            when 'this_year'
              (Date.today.beginning_of_year..Date.today).select {|d| d.day == 1}
          end
    [range, daily_report]
  end
  
  # return report period column title
  def report_period_to_title
    case self
      when 'this_month'
        'Days'
      when 'last_month'
        'Days'
      when 'last_6_months'
        'Months'
      when 'this_year'
        'Months'
    end
  end

  # convert boolean strings into boolean format
  def to_bool
    return true if ['true', '1', 'yes', 'on', 't'].include? self
    return false if ['false', '0', 'no', 'off', 'f'].include? self
    return false
  end

  # remove all bad words of current text
  # @param report_model: object to report if there is a bad word in current string
  # @return parsed string
  def remove_bad_words(report_model = nil)
    all_words = Word.all_words
    contain_bad_words = false
    res = self.gsub(/\b\w+\b/) do |word|
      if all_words.include?(word.downcase)
        contain_bad_words = true
        '***'
      else
        word
      end
    end.squeeze(' ')
    Report.where(description: 'Contain bad words', target: report_model).first_or_create if contain_bad_words
    res
  end
end