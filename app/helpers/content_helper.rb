module ContentHelper
  def posted_time(content)
    mess = ''
    second_diff = Time.now - content.created_at
    min_diff = (second_diff / 60).to_i
    hours_diff = (min_diff / 60).to_i
    if min_diff < 1
      mess = 'Just now'
    elsif  min_diff < 60
      mess = "#{pluralize min_diff, 'minute'} ago"
    elsif hours_diff < 24
      mess = "#{pluralize hours_diff, 'hour'} ago"
    else
      pretty_time content.created_at
    end
  end

  def render_content_item(content, **options)
    partial_name = content.content_type
    if options[:type].present?
      partial_name = "#{options[:type]}_#{partial_name}"
    end
    render partial: "dashboard/contents/#{partial_name}", locals: {
      content: content
    }
  end

  def sanitized_preview(content)
    tags = %w(h1 h2 h3 img b p strong em u a li br blockquote div footer)
    sanitize(content, tags: tags, attributes: %w(href id class style src data-id target))
  end

  def pure_text(content)
    simple_format(content)
  end

  def embeded_youtube_video youtube_id
    content_tag :div, nil, class: 'youtube', data: { id: youtube_id, params: 'modestbranding=1&showinfo=0&rel=0' }
  end

  def inject_embeded_youtube_videos text
    match_data = text.scan(/(?<link>(https?:\/\/)?(www\.)?youtube.com\/watch\?(.*\&)?v=(?<id>[\d\w-]+))/)
    doc = Nokogiri::HTML::DocumentFragment.parse text
    if match_data.present?
      match_data.each do |(link, id)|
        element = doc.css("a[href=\"#{link}\"]").first
        element.replace(embeded_youtube_video(id)) if element.present?
      end
    end
    doc.to_s
  end

  def prepare_story_text text
    inject_embeded_youtube_videos(text)
  end

  # return the greeting cookie key for today
  def greeting_cookie
    "greetings_#{current_user.try(:id)}_#{Date.today.to_s.underscore}"
  end

  # hide the greeting card
  def hide_greeting_card
    cookies[greeting_cookie] = {value: 'hidden', expires: Time.current.end_of_day }
  end
  
  # bible books ready to be used this endpoint: https://getbible.net/api
  # return the bible books data ready to be cached in controller or anywhere 
  def bible_books_helper
    res = {}
    req = Net::HTTP.get_response(URI.parse('https://getbible.net/index.php?option=com_getbible&task=bible.books&format=json&v=kjv'))
    JSON.parse(req.body[1...-2]).map{|book|
      req2 = Net::HTTP.get_response(URI.parse("https://getbible.net/index.php?option=com_getbible&task=bible.chapter&format=json&v=asv&nr=#{book['book_nr']}"))
      book['chapters'] = JSON.parse(req2.body[1...-2]).count
      res[book['ref']] = book
    }
    res
  end
  
  # return all required data for content widget
  def content_widget_data(content)
    {data: {content_id: content.id, key: content.public_uid, callback: 'DashboardContent:init'}, class: "#{content.content_type} hook_caller", id: "content-#{content.id}"}
  end
  
  # calculate font size based on qty of characters in content body
  # return (String) 'font-size: 10px'
  def feed_font_size_text(content)
    qty = ActionView::Base.full_sanitizer.sanitize(content.description).length
    size = 14
    size = 45 if qty.between?(0, 20)
    size = 30 if qty.between?(21, 40)
    size = 25 if qty.between?(41, 60)
    size = 18 if qty.between?(61, 80)
    "font-size: #{size}px;"
  end
  
  # key: friends | groups
  # returns {display: (boolean) flag to show or not suggested friends, mode: (string) mode of display: full | half | simple}
  def calculate_suggested_friends_frequency(page = 1)
    return {display: false} if @displayed_user
    page = (page || 1).to_i
    modes = ['full', 'half', 'simple']
    mode = modes[rand(0..2)]
    mode = 'full' if page == 1 && current_user.qty_friends < 5
    pages = Rails.cache.fetch("calculate_suggested_friends_frequency_#{current_user.id}", expire_at: Time.current.end_of_day) do
      start = rand(1..5)
      start = 1 if current_user.qty_friends < 5
      step = if current_user.qty_friends < 20
               3
             elsif current_user.qty_friends < 50
               4
             elsif current_user.qty_friends < 100
               5
             elsif current_user.qty_friends < 300
               6
             elsif current_user.qty_friends < 500
               7
             elsif current_user.qty_friends < 800
               8
             elsif current_user.qty_friends < 1000
               9
             else
               10
             end
      (start..100).step(step).to_a
    end
    {display: pages.include?(page), mode: mode}
  end

  # Verify to show or not the suggested groups
  # Return boolean
  def calculate_suggested_groups_frequency(page = 1)
    page = (page || 1).to_i
    pages = Rails.cache.fetch("calculate_suggested_groups_frequency_#{current_user.id}", expire_at: Time.current.end_of_day) do
      step = if current_user.qty_friends < 20
               6
             elsif current_user.qty_friends < 50
               7
             elsif current_user.qty_friends < 100
               8
             elsif current_user.qty_friends < 300
               9
             elsif current_user.qty_friends < 500
               10
             elsif current_user.qty_friends < 800
               11
             elsif current_user.qty_friends < 1000
               12
             else
               13
             end
      start = rand(1..6)
      (start..100).step(step + 3).to_a
    end
    pages.include?(page.to_i)
  end
end