class Dashboard::SearchController < Dashboard::BaseController
  include UserGroupHelper
  respond_to :json, :html
  def index
    params[:type] = 'all' unless params[:type]
    @people = User.valid_users.exclude_blocked_users(current_user).search(params[:filter]).order(qty_friends: :DESC)
    @counselors = User.all_mentors.search(params[:filter]).order(qty_friends: :DESC)
    @churches = UserGroup.churches.search(params[:filter]).order(updated_at: :DESC)
    @groups = UserGroup.exclude_churches.search(params[:filter]).order(updated_at: :DESC)
    @events = Event.search(params[:filter]).order(updated_at: :DESC)
    @contents = NewsfeedService.new(current_user, params[:page], 10).recent_content.search(params[:filter])
    # @contents = NewsfeedService.new(current_user, params[:page], 10).recent_content.search_elastic(params[:filter]).records # TODO implement elastic search
    
    case params[:type]
      when 'counselors'
        @items = @counselors
      when 'churches'
        @items = @churches
      when 'groups'
        @items = @groups
      when 'events'
        @items = @events
      when 'contents'
        @items = @contents
      when 'people'
        @items = @people
      when 'all'
        @people = extra_search_actions(@people, params[:extra_filter], 'people')
        @counselors = extra_search_actions(@counselors, params[:extra_filter], 'counselors')
        @churches = extra_search_actions(@churches, params[:extra_filter], 'churches')
        @groups = extra_search_actions(@groups, params[:extra_filter], 'groups')
        @events = extra_search_actions(@events, params[:extra_filter], 'events')
        @contents = extra_search_actions(@contents, params[:extra_filter], 'contents')
    end
    @items = extra_search_actions(@items, params[:extra_filter]).page(params[:page]).per(10) if params[:type] != 'all'
    render 'results' if request.format == 'text/javascript'
  end

  # search auto complete data
  def get_autocomplete_data
    results = {}
    results[:hash_tags] = HashTag.search(params[:search]).order(updated_at: :DESC).select(:id, :name).limit(5) if params[:kind] == 'tags'
    # results[:contents] = NewsfeedService.new(current_user, 1, 5).popular_content.search_elastic(params[:search]).records.map{|c| {id: c.id, title: c.the_title} } if params[:kind] == 'contents' # TODO search by elasticsearch
    results[:contents] = NewsfeedService.new(current_user, 1, 5).popular_content.map{|c| {id: c.id, title: c.the_title} } if params[:kind] == 'contents'
    results[:users] = User.valid_users.exclude_blocked_users(current_user).search(params[:search], email: true).limit(5).select(:id, :first_name, :last_name, :email) if params[:kind] == 'users'
    results[:groups] = UserGroup.search(params[:search]).limit(5).select(:id, :name) if params[:kind] == 'groups'
    render json: results
  end

  # return all online users
  def get_online_users
    render json: current_user.friends.online.pluck(:id)
  end

  # filter users according extra params: exclude, users_id, not_in_group, not_in_conversation, users_id
  def get_users
    users = case params[:kind]
              when 'friends'
                current_user.friends
              when 'counselor'
                User.all_mentors
              when 'official_counselor'
                User.official_mentors
              when 'other_counselor'
                User.other_mentors
              when 'group_members'
                current_user.user_groups.find(params[:user_group_id]).members
              else
                User.valid_users.exclude_blocked_users(current_user)
            end
    users = filter_users(users).page(params[:page]).per(params[:per_page])
    render json: users.name_sorted.to_json(only: [:id, :full_name, :email, :avatar_url, :mention_key])
  end

  # return 10 recommended users to answer a question (most commenter users)
  def recommended_users
    limit = params[:limit] || 10
    exclude = params[:exclude].is_a?(Array) ? params[:exclude] : params[:exclude].to_s.split(',')
    attrs = {only: [:id, :full_name, :email, :avatar_url, :mention_key]}
    users = case params[:kind] || 'answer' 
              when 'answer'
                attrs = {methods: :qty_comments}
                current_user.answer_recommended_users(exclude + [current_user.id], "#{params[:content]} #{params[:title]}", limit)
              when 'pray'
                current_user.friends.most_active.where.not(id: exclude).limit(limit)
            end
    render json: users.to_json(attrs)
  end
  
  def user_professions
    data = User::PROFESSIONS
    res = []
    data.each do |k,v| 
      res << {id: k, label: v} unless (v =~ /#{params[:search]}/i).nil?
    end
    render json: res
  end
  
  # return full information of a google place
  # required: place_id
  def google_place_info
    @data = google_map_place_info(params[:place_id])
  end
  
  private
  
  # filter users according extra params
  def filter_users(users)
    exclude = params[:exclude].is_a?(Array) ? params[:exclude] : params[:exclude].to_s.split(',')
    if params[:not_in_group].present? # exclude members of a user group
      users = users.where.not(id: UserGroup.where(id: params[:not_in_group]).take.members.pluck(:id))
    end
    if exclude.include?('mentors') # exclude mentors
      users = users.skip_mentors
    end
    if exclude.include?('other_mentors')
      users = users.skip_other_mentors
    end
    if exclude.include?('official_mentors')
      users = users.skip_official_mentors
    end
    if params[:not_in_conversation].present? # exclude members of conversation
      users = users.where.not(id: Conversation.find(params[:not_in_conversation]).conversation_members.pluck(:user_id))
    end

    exclude.each do |item|
      users = users.where.not(id: MentorCategory.find(item.split('mentor_category_').last).users.pluck(:id)) if item.to_s.start_with?('mentor_category_')
    end
    
    users = users.where(id: params[:users_id].is_a?(Array) ? params[:users_id] : params[:users_id].split(',')) if params[:users_id].present?
    users = users.search(params[:search], mention: true) if params[:search].present?
    users.where.not(id: exclude.uniq.delete_empty).uniq
  end
  
end
