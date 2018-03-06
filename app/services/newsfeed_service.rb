class NewsfeedService
  # pagination attributes: page, per_page
  # user: current user visitor
  def initialize user, page = 1, per_page = 20
    @per_page = per_page
    @user = user
    @page = page.presence || 1
  end

  # return user's own feeds for profile
  # @param is_current_user: (Boolean) if true will include anonymous feeds, default false
  def profile_feeds(is_current_user = false)
    res = @user.contents.includes(:hash_tags, :owner, :user).ignore_daily_devotions
    unless is_current_user
      @user.user_anonymities.pluck(:start_time, :end_time).each do |range|
        res = res.where.not(created_at: range.first..(range.last || Time.current))
      end
    end
    res.order(created_at: :desc).page(@page).per(@per_page)
  end

  # order by popularity
  def popular_content
    query = [@user.following_shared_contents.to_sql, @user.following_contents.to_sql, @user.contents.to_sql].map{|v| " (#{v}) " }.join(' UNION ')
    res = Content.from("(#{query}) as contents")
              .select("contents.*, #{score_select_sql}")
              .order('score_date DESC, score_priority DESC, contents.last_activity_time DESC')
              .newsfeed_for(@user.id)
    res = res.page(@page).per(@per_page).includes(:hash_tags, :user)
    # res.instance_variable_set(:@total_count, Rails.cache.fetch("cache-total-popular-#{@user.id}", expires_in: 1.hours){ res.except(:select, :limit, :offset, :order).count })
    res
  end

  # return the past popular contents in a period (last logout until last login) 
  # show this for 5 mins
  # show feeds older than 2 days
  def past_popular
    if @page == 1 && @user.last_sign_out_at.present? && @user.last_sign_out_at <= 2.days.ago && @user.current_sign_in_at >= 1.minutes.ago
      popular_in(@user.last_sign_out_at, @user.last_sign_in_at).limit(6).includes(:hash_tags, :user, :owner).to_a
    else
      []
    end
  end
  
  # return the popular contents in a period 
  def popular_in(from, to)
    popular_content.where(last_activity_time: from..to)
  end

  # order by recent created at
  #   tag_id: filter content for a specific tag 
  def recent_content(tag_id = nil)
    query = [@user.following_shared_contents.to_sql, @user.following_contents.to_sql, @user.contents.to_sql].map{|v| " (#{v}) " }.join(' UNION ')
    res = Content.from("(#{query}) as contents")
              .order('contents.created_at DESC')
              .newsfeed_for(@user.id)
    res = res.joins(:contents_hash_tags).where('contents_hash_tags.hash_tag_id = ?', tag_id) if tag_id
    res = res.page(@page).per(@per_page).includes(:user)
    # res.instance_variable_set(:@total_count, Rails.cache.fetch("cache-total-recent-content-#{@user.id}", expires_in: 1.hours){ res.except(:select, :limit, :offset, :order).count }) #TODO verify hash error
    res
  end
  
  # The trending card has to show the most popular content on the site at that particular moment. 
  # It should be same for all the users and irrespective of whether content is made by friend of user or not. 
  # You should make this real time by ranking the newest content on the site. Amongst the ranked newest content at that particular time, anonymous posts; posts with more reactions, comments, shares, gets ranked higher on the list.
  def public_popular_in(time_range)
    Content.public_content.popular.where(content_actions: {created_at: time_range}).page(@page).per(@per_page).includes(:hash_tags, :user)
  end
  
  # return popular global content: make it to show within last hour and return for within 24 hours if it’s list returns empty
  def widget_popular_content
    res = public_popular_in(1.hour.ago..Time.current)
    unless res.except(:select, :order).any?
      res = public_popular_in(1.day.ago..Time.current)
    else
      return res
    end
    
    unless res.except(:select, :order).any?
      res = public_popular_in(1.month.ago..Time.current)
    else
      return res
    end
    res = public_popular_in(6.months.ago..Time.current) unless res.except(:select, :order).any?
    res
  end

  private
  # return the score calculator select
  def score_select_sql
    '(contents.last_activity_time::timestamp::date) as score_date,
    (contents.cached_votes_score + contents.shares_count + contents.comments_count - contents.reports_counter) as score_priority'
  end
end
