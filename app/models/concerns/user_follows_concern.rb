module UserFollowsConcern extend ActiveSupport::Concern
  included do
    has_many :active_relationships, class_name:  'Relationship', foreign_key: 'follower_id', dependent: :destroy
    has_many :following, ->(obj){ obj.is_a?(User) ? without_roles(:banned).where.not(id:obj.id) : without_roles(:banned) }, through: :active_relationships, source: :followed
    has_many :following_contents, ->{ visible_by_others }, through: :following, source: :contents
    has_many :following_shared_contents, ->{ visible_by_others }, through: :following, source: :shared_contents
    has_many :passive_relationships, class_name:  'Relationship', foreign_key: 'followed_id', dependent: :destroy
    has_many :followers, ->{ without_roles(:banned) }, through: :passive_relationships, source: :follower

    has_many :follow_suggestions, ->{ fellowship }, as: :suggestandable, class_name: 'SuggestedUser'
    has_many :my_suggested_following_users, through: :follow_suggestions, class_name: 'User', source: :user
    has_many :rejected_follow_suggestions, ->{ where(kind: 'rejected_follow_suggestion') }, as: :banable, class_name: 'BannedUser'
  end

  # check if a content was shared by following
  def content_shared_by_following?(_content)
    Rails.cache.fetch("content_shared_by_following_#{id}_#{_content.id}", expires_in: 7.days.from_now) do
      following_shared_contents.where(id: _content.id).any?
    end
  end

  # return last <Share> made by followings to specific a content 
  def content_following_sharers(_content_id)
    Share.from("(#{following_shared_contents.where(id: _content_id).select('shares.*').to_sql}) as shares").where.not(user_id: id).newer
  end

  # return all suggested following users
  # page: (Integer) number of page
  def suggested_users(page = 1, per_page = 15)
    calc_suggested_following
    my_suggested_following_users.where.not(id: rejected_follow_suggestions.pluck(:user_id)).page(page).per(per_page)
  end

  def see_contacts(another_user)
    following.include? another_user
  end
  
  def follow(other_user)
    unless active_relationships.where(followed_id: other_user.id).any?
      active_relationships.create(followed_id: other_user.id)
      reset_cache(['dashboard_header', 'suggested_users', 'feed_popular_counter'])
      other_user.reset_cache(['dashboard_header', 'suggested_users', 'feed_popular_counter'])
    end
    follow_suggestions.where(user_id: other_user.id).delete_all
    reset_following_cache(other_user)
  end

  # ignore a specific following suggestion
  def ignore_suggested_following(_user_id)
    follow_suggestions.where(user_id: _user_id).delete_all
    rejected_follow_suggestions.create(user_id: _user_id)
  end
  
  # Unfollows a user.
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).try(:destroy)
    reset_cache(['dashboard_header', 'suggested_users', 'feed_popular_counter'])
    other_user.reset_cache(['dashboard_header', 'suggested_users', 'feed_popular_counter'])
    reset_following_cache(other_user)
  end

  # Stops be following by other user
  # TODO: block other user to prevent future following again
  def unfollowed(other_user)
    passive_relationships.find_by(follower_id: other_user.id).try(:destroy) 
  end
  
  # Returns true if the current user is following the other user.
  def following?(other_user_id)
    _user_id = other_user_id.try(:id) || other_user_id
    Rails.cache.fetch("user-following-#{get_cache_key}-#{_user_id}", expires_in: 1.month.from_now) do
      following.where(id: _user_id).any?
    end
  end
  
  # reset all following cache related to other user
  def reset_following_cache(other_user)
    update_column(:user_cache_key, Time.current)
    other_user.update_column(:user_cache_key, Time.current)
  end

  def cache_key_simple_user_json(other_user)
    "simple-user-json-#{id}-#{other_user.id}-#{updated_at.to_i}"
  end
  
  def num_of_followers
    if ['yaw@loverealm.org', 'sparklinguy2002@yahoo.com'].include? self.email
      followers.count + 21234
    else
      followers.count
    end
  end

  def search_following(search_term, page, per_page)
    self.following.
        where('LOWER(first_name) like ? OR LOWER(last_name) like ? OR LOWER(email) like ?', "%#{search_term.downcase}%", "%#{search_term.downcase}%", "%#{search_term.downcase}%").
        page(page).per(per_page)
  end

  # logic to calculate follow suggestions
  def calc_suggested_following
    Rails.cache.fetch("suggested_user_following_#{id}", expires_in: 1.weeks.from_now.end_of_day) do
      follow_suggestions.delete_all
      queries = _possible_friends.map{|q|
        "(#{q.
            where.not(id: rejected_follow_suggestions.pluck(:user_id)).
            where("NOT EXISTS(#{Relationship.where(follower_id: id).where('relationships.followed_id = users.id').select(:id).to_sql})").
            to_sql
        })"
      }.join(' UNION ')
      res = User.from("(#{queries}) as users").uniq.order('u_priority ASC, pref_priority DESC')
      res.pluck('users.id, u_priority, pref_priority').map{|a| follow_suggestions.create!(user_id: a.first) }
    end
  end
end