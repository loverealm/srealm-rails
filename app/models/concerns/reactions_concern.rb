module ReactionsConcern extend ActiveSupport::Concern
  # TODO: support same reactions for comments and answers

  # check if _user voted for current object
  def is_liked_by?(_user)
    reacted_by(_user).present?
  end

  # return the reaction made by user for current content
  def reacted_by(_user)
    Rails.cache.fetch(custom_cache_key("reactionn_by_#{_user.try(:id) || _user}", 'last_activity_time'), expires_in: 5.days) do
      votes_for.where(voter_id: _user).take
    end
  end
  
  # makes liked current post for _user
  # mode or kind of reaction: love, wow, pray, amen, angry, sad (default love)
  def like_for(_user, mode = 'love', fake = false)
    mode = mode.presence || 'love'
    return if !fake && is_liked_by?(_user) && reacted_by(_user).vote_scope == mode # skip if there already exist the same reaction
    if !fake && (vote = votes_for.where(voter_id: _user, voter_type: 'User').take).present?
      vote.update(vote_scope: mode)
    else
      votes_for.create!(vote_scope: mode, vote_weight: 1, voter: _user)

      sett = {foreground: true}
      PubSub::Publisher.new.publish_for([user], 'like_alert', {source: as_basic_json, user: _user.as_basic_json, fake: fake}, _reaction_notification_message(_user)) if user.id != _user.id
      trigger_instant_notification('like', {source: as_basic_json, user: _user.as_basic_json, fake: fake}, sett.merge(group: "reaction_#{id}"))
      _track_content_action('liked') unless fake
      if !fake && user.id != _user.id
        create_activity action: 'like', recipient: user, owner: _user unless public_activity_previous('content.like', user)
      end
    end

    # if user taps on ‘pray’ on card with prayer request it should add to prayer request
    if !fake && mode == 'pray' && self.is_pray?
      t = Time.current
      req = content_prayers.where(user_id: _user.id).first_or_create!(user_requester_id: user_id, accepted_at: t)
      req.update(accepted_at: t, rejected_at: nil)
    end
    votes_update_cache
    
    if user.is_promoted? || users_sharers.promoted.any?
      if Setting.get_setting(:promoted_factor_way) == '1' # factor way
        Delayed::Job.enqueue(LongTasks::PromotedLikesByFactor.new(id)) unless fake
      else # period way
        if cached_votes_score == 2 # check for promoted user's content (generate fake reactions)
          Rails.cache.fetch("started_fake_likes_for_#{id}") do
            Delayed::Job.enqueue(LongTasks::PromotedLikes.new(id))
          end
        end
      end
    end
  end

  def unlike_for(_user)
    votes_for.where(voter_id: _user, voter_type: 'User').destroy_all
    trigger_instant_notification('unlike', {source: as_basic_json, user: _user.as_basic_json}, {foreground: true})
    votes_update_cache
  end
  
  # votes
  #   kind: love, wow, pray, amen, angry, sad (default love)
  def reactions_for(vote_kind = 'love')
    vote_kind = vote_kind.presence || 'love'
    find_votes_for(vote_scope: vote_kind)
  end

  # voters
  #   kind: love, wow, pray, amen, angry, sad (default love)
  def voters_for(vote_kind = 'love')
    User.most_active.joins('INNER JOIN "votes" ON "votes"."voter_id" = "users"."id"').merge(reactions_for(vote_kind)).select('users.*, votes.created_at as voted_at, votes.vote_scope')
  end

  # return all voters for current contnet
  def voters
    User.most_active.joins('INNER JOIN "votes" ON "votes"."voter_id" = "users"."id"').merge(votes_for).select('users.*, votes.created_at as voted_at, votes.vote_scope')
  end
  
  def votes_update_cache
    update_column(:cached_love, reactions_for('love').count)
    update_column(:cached_pray, reactions_for('pray').count)
    update_column(:cached_amen, reactions_for('amen').count)
    update_column(:cached_angry, reactions_for('angry').count)
    update_column(:cached_sad, reactions_for('sad').count)
    update_column(:cached_wow, reactions_for('wow').count)
    update(cached_votes_score: votes_for.count)
  end
  
  # return the quantity of total votes (taking care for promoted users)
  def the_total_votes
    res = cached_votes_score
    res
  end
  
  # return the real votes for current content (exclude fake reactions)
  def the_real_total_votes
    @_cache_the_real_total_votes ||= votes_for.where.not(voter_id: User.anonymous_id).count
  end

  # return friends of _user who voted for current content
  #   kind: love, wow, pray, amen, angry, sad (default love)
  def friends_in_votes_of(_user)
    _user.friends.most_active.joins('INNER JOIN "votes" ON "votes"."voter_id" = "users"."id"').merge(votes_for).select('users.*, votes.created_at as voted_at, votes.vote_scope')
  end
  
  def reaction_notification_body
    list = []
    top_friends = friends_in_votes_of(user).order('voted_at DESC').limit(2).map{|u| u.the_first_name(u.voted_at) }
    reacted = reacted_by(user).present?
    list << 'You' if reacted
    list += top_friends if top_friends.any?
    qty = cached_votes_score - list.length
    list << "#{qty} others" if qty > 0
  end
  
  # generate certain quantity if fake likes and fake file visits
  # @param qty {Integer}: Quantity of fake likes, also this indicates the max number for random fake file visits
  def generate_fake_likes(qty)
    reactions = ['love', 'wow', 'pray', 'amen', 'angry', 'sad']
    qty.times.to_a.each do
      like_for(User.anonymous, reactions[rand(0..5)], true)
    end

    if is_media? # fake views for videos
      content_images.each do |file|
        unless file.is_image?
          rand(qty).times.to_a.each do
            file.content_file_visitors.create!(user: User.anonymous)
          end
        end
      end
    end
  end
  
  # send ios reaction notification
  # @param _user: (User model) user who reacted to current content
  def _reaction_notification_message(_user)
    res = {}
    unique_users = votes_for.pluck(:voter_id).uniq
    if unique_users.size == 1
      res = {title: "", body: "#{User.find(unique_users[0]).full_name(false, created_at)} #{content_type == "pray" ? 'is praying with you' : "loves your #{content_type.to_s.titleize}"}"}
    elsif unique_users.size == 2
      res = {title: '', body: "#{User.find(unique_users[0]).full_name(false, created_at)} and #{User.find(unique_users[1]).full_name(false, created_at)} #{content_type == "pray" ? 'are praying with you' : "love your #{content_type.to_s.titleize}"}"}
    else
      user_numbers = unique_users.size - 1
      user_numbers = user_numbers - 1 if unique_users.include?(user.id)
      res = {title: '', body: "#{User.find(unique_users[0]).full_name(false, created_at)} + #{user_numbers} #{content_type == "pray" ? 'others are praying with you' : "others love your #{content_type}"}"}
    end
    res
  end
end