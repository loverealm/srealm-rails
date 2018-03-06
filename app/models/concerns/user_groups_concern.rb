module UserGroupsConcern extend ActiveSupport::Concern
  included do
    has_many :my_user_groups, class_name: 'UserGroup' # groups where current user is the owner
    has_many :group_user_relationships, ->{ where(groupable_type: 'UserGroup').accepted }, class_name: 'UserRelationship' # user group relationships where user is member of
    has_many :admin_group_user_relationships, ->{ where(groupable_type: 'UserGroup').accepted.admin }, dependent: :destroy, class_name: 'UserRelationship' # user group relationships where user is admin member of
    has_many :admin_user_groups, through: :admin_group_user_relationships, source: :groupable, source_type: 'UserGroup' # return all groups where current user is member of and current user is admin of
    has_many :user_groups, through: :group_user_relationships, source: :groupable, source_type: 'UserGroup' # return all groups where current user is member of
    has_many :user_groups_members, through: :user_groups, source: :members # all members of my user groups
    has_many :user_groups_events, through: :user_groups, source: :events # all events of my user groups
    has_many :churches, ->{ churches }, through: :group_user_relationships, source: :groupable, source_type: 'UserGroup' # return all groups where current user is member of and current user is admin of
    has_many :church_counselors, ->{ distinct }, through: :churches, source: :counselors # all counselors of all churches
  end

  # return the primary church for current user
  def primary_church
    @_cache_primary_church ||= lambda {
      _rel = group_user_relationships.primary.first
      unless _rel
        _rel = group_user_relationships.first
        _rel.update_column(:is_primary, true) if _rel
      end
      user_groups.find_by_id(_rel.try(:groupable_id))
    }.call
  end

  # set default church for current user
  def set_default_church(_user_group_id)
    _group_rel = group_user_relationships.where(groupable_id: _user_group_id).take
    return errors.add(:base, 'You are not member of this group') && false unless _group_rel
    group_user_relationships.update_all(is_primary: false)
    _group_rel.update_column(:is_primary, true)
  end

  # return all user groups where current user is member of and branches where current user is admin of main group
  def all_user_groups
    UserGroup.joins(:user_relationships).uniq.where("user_relationships.user_id = ? or user_groups.parent_id IN (?)", id, admin_user_groups.pluck(:id))
  end
  
  # return paginated suggested user groups for current user
  def suggested_groups(page = 1, per_page = 20)
    @_cache_suggested_user_groups ||= lambda{
      suggested_user_group_ids = Rails.cache.fetch("suggested_user_groups_for_#{id}", expires_in: Time.current.end_of_day){
        prio = UserGroup.with_hash_tags(hash_tags.pluck(:id)).select('*, 1 prio')
        all = UserGroup.where.not(id: user_groups.pluck(:id)).select('*, 0 prio')
        UserGroup.from("(#{prio.to_sql} UNION #{all.to_sql}) as user_groups")
            .uniq
            .order('prio DESC')
            .limit(300)
            .where.not(id: user_groups.pluck(:id))
            .pluck(:id, :prio).map{|a| a.first }
      }
      res = Kaminari.paginate_array(suggested_user_group_ids).page(page).per(per_page)
      res.replace(UserGroup.where(id: res).to_a)
      res
    }.call
  end
  
  def reset_suggested_groups
    Rails.cache.delete("suggested_user_groups_#{id}")
  end

  # return the quantity of new feeds since the last visit of an specific user group
  def count_new_feeds_for_user_group(_user_group_id)
    group = user_groups.find_by_id(_user_group_id)
    if group
      l = group.feeds.where.not(user_id: id)
      _last_visit = get_user_group_relationship(_user_group_id).try(:last_visit)
      l = l.where('contents.created_at > ?', _last_visit) if _last_visit
      l.count
    else
      0
    end
  end
  
  # update the last visit group of current user into certain user group
  def update_last_visit_group_for!(_user_group_id)
    rel_group = get_user_group_relationship(_user_group_id)
    if rel_group
      rel_group.update_column(:last_visit, Time.current)
    else
      errors.add(:base, 'You are not member is this user group') && false
    end
  end
  
  # return the user group relationship of current user and specific user group
  def get_user_group_relationship(_user_group_id)
    group_user_relationships.where(groupable_id: _user_group_id).take
  end
end