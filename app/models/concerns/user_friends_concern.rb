module UserFriendsConcern extend ActiveSupport::Concern
  included do
    has_many :user_friend_relationships, dependent: :destroy # requests from this user
    has_many :received_friend_relationships, class_name: 'UserFriendRelationship', foreign_key: :user_to_id, dependent: :destroy # requests to this user
    has_many :friend_suggestions, ->{ friendship }, as: :suggestandable, class_name: 'SuggestedUser'
    has_many :my_suggested_friends, through: :friend_suggestions, class_name: 'User', source: :user
    has_many :rejected_friend_suggestions, ->{ where(kind: 'rejected_friend_suggestion') }, as: :banable, class_name: 'BannedUser'
  end

  # current user's friends
  def friends
    User.joins('INNER JOIN "user_friend_relationships" ON "user_friend_relationships"."user_to_id" = "users"."id" OR "user_friend_relationships"."user_id" = "users"."id" ').merge(UserFriendRelationship.friends_for(id)).where.not(id: id).uniq
  end
  
  # pending to be accepted by this user
  def pending_friends
    User.where('users.id in (?)', UserFriendRelationship.pending.where(user_to_id: id).pluck(:user_id))
  end

  # return the friendship with a specific user
  def friendship_with(_user_id)
    UserFriendRelationship.between(id, _user_id)
  end

  # check if current user if friend of _user_id
  def is_friend_of? _user_id
    Rails.cache.fetch("cache-is_friend_of-#{id}-#{_user_id}") do
      friends.where(id: _user_id).any?
    end
  end
  
  # return all suggested friends paginated
  # page: (Integer) number of page
  def suggested_friends(page = 1, per_page = 15)
    calc_suggested_friends
    my_suggested_friends.where.not(id: rejected_friend_suggestions.pluck(:user_id) + [User.bot_id]).page(page).per(per_page)
  end
  
  # create a new user request for user_id
  def add_friend_request(user_id)
    friend_suggestions.where(user_id: user_id).delete_all
    req = pending_friends.where(id: user_id).first
    if req.present?
      req.accept!
    else
      req = UserFriendRelationship.between(user_id, id).first || user_friend_relationships.create(user_to_id: user_id)
      PubSub::Publisher.new.publish_for([req.user_to], 'friend_request', {source: self.as_basic_json}, {title: full_name(false), body: 'wants to be your friend'})
    end
    # reset_cache('suggested_friends')
  end

  # Ignore specific suggested friend. This user will not be suggested anymore for current user.
  def ignore_suggested_friend(_user_id)
    rejected_friend_suggestions.create!(user_id: _user_id)
    friend_suggestions.where(user_id: _user_id).delete_all
  end

  # verify if today is time to show the invite friends modal (every 30 days)
  def can_show_invite_friends?
    (Date.today - (invited_friends_at || created_at).to_date).to_i >= 30
  end
  
    # mark current user as shown the invite friends for current month
  def shown_invite_friends!
    update_column(:invited_friends_at, Time.current)
  end

  # return friend status
  def friend_status(user_id)
    instance_cache_fetch("friend_status_#{user_id}") do
      req = UserFriendRelationship.between(id, user_id).first
      return '' unless req.present?
      if req.user_id == id # sent
        return 'rejected' if req.rejected_at.present?
        return 'friends' if req.accepted_at.present?
        'sent'
      else # received
        return 'rejected' if req.rejected_at.present?
        return 'friends' if req.accepted_at.present?
        'pending'
      end
    end
  end
  
  # private
  # logic to calculate friend suggestions
  def calc_suggested_friends
    Rails.cache.fetch("suggested_user_friends_#{id}", expires_in: 1.weeks.from_now.end_of_day) do
      friend_suggestions.delete_all
      queries = _possible_friends.map{|q|
        "(#{q.
            where.not(id:  rejected_friend_suggestions.pluck(:user_id)).
            where("NOT EXISTS(#{UserFriendRelationship.where('user_id = ? or user_to_id = ?', id, id).where('user_id = users.id or user_to_id = users.id').select(:id).to_sql})").
            to_sql
        })"
      }.join(' UNION ')
      res = User.from("(#{queries}) as users").uniq.order('u_priority ASC, pref_priority DESC')
      res.pluck('users.id, u_priority, pref_priority').map{|a| friend_suggestions.create(user_id: a.first) }
    end
  end
  
  # calculate all possible friends according preferences
  # @param _limit: limit per group
  def _possible_friends(_limit = 100)
  
    query = []
  
    # select columns
    # order by priorities
    order_prio = ['(case when 1 = 1 then 0 end)']
    order_prio << "(case when users.sex = #{preferred_sex} then 1 else 0 end)" if preferred_sex.present?
    order_prio << "(case when users.sex = #{opposite_sex} then 1 else 0 end)" if preferred_friendship == 'marriage'
    if preferred_countries.present?
      order_prio << "(case when users.country in (#{preferred_countries.map{|a| User.sanitize(a) }.join(',')}) then 1 else 0 end)"
      order_prio << "(case when meta_info->>'continent'= #{User.sanitize(continent)} then 1 else 0 end)"
    end
    order_prio << "(case when extract(year from users.birthdate::DATE) BETWEEN #{preferred_age.split(',').join(' and ')} then 1 else 0 end)" if preferred_age.present?
  
    selects = "users.*, (#{order_prio.join(' + ')}) as pref_priority, %{prio} as u_priority"
  
    # mobile contacts
    query << User.most_active.where(phone_number: user_settings.contact_numbers).select(selects % {prio: 1}) if user_settings.contact_numbers.present?
  
    # users in the same group
    query << User.most_active.joins(:user_relationships).where(user_relationships: {groupable_id: user_groups.pluck(:id)}).where('user_relationships.accepted_at is not null').select(selects % {prio: 2}) if user_groups.any?
  
    # filter by country
    # if preferred_countries.present?
    #   query << User.most_active.where(country: preferred_countries).select(selects % {prio: 3})
    #   query << User.most_active.where("meta_info->>'continent'= ?", continent).select(selects % {prio: 4})
    # end
  
    query << User.valid_users.select(selects % {prio: 10}) # default suggestion
  
    # filter by sex
    # sexs = []
    # sexs << preferred_sex if preferred_sex.present?
    # sexs << opposite_sex if preferred_friendship == 'marriage'
    # query = query.map{|q| q.where(sex:sexs ) } if sexs.present?
  
  
    # filter by age
    # query = query.map{|q| q.between_ages(*preferred_age.split(',')) } if preferred_age.present?
  
    query.map{|q| q.where.not(id: [id, User.bot_id] + blocked_user_ids).limit(_limit) }
  end
end