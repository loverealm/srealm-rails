module UserGroupBranchesConcern extend ActiveSupport::Concern
  included do
    belongs_to :main_branch, class_name: 'UserGroup', foreign_key: :parent_id
    has_many :branches, class_name: 'UserGroup', foreign_key: :parent_id, dependent: :destroy
    has_many :user_group_branch_requests_sent, ->{ pending }, class_name: 'UserGroupBranchRequest', foreign_key: :user_group_from_id, inverse_of: :user_group_from
    has_many :user_group_branch_requests_received, ->{ pending }, class_name: 'UserGroupBranchRequest', foreign_key: :user_group_to_id
    has_many :received_request_branches, class_name: 'UserGroup', through: :user_group_branch_requests_received, source: :user_group_from
    has_many :sent_request_branches, class_name: 'UserGroup', through: :user_group_branch_requests_sent, source: :user_group_to
    after_save :check_branch_request
    attr_accessor :request_root_branch
  end

  # requests sent and requests received
  def all_branch_requests(req_filter = {})
    req_received = received_request_branches.where(user_group_branch_requests:UserGroupBranchRequest.pending.where_values_hash).where(req_filter).select('user_groups.*, user_group_branch_requests.kind as request_kind')
    req_sent = sent_request_branches.where(user_group_branch_requests:UserGroupBranchRequest.pending.where_values_hash).where(req_filter).select('user_groups.*, user_group_branch_requests.kind as request_kind')
    UserGroup.from("(#{req_received.to_sql} UNION #{req_sent.to_sql}) as user_groups").uniq 
  end

  #*************** requests to be a branch of _user_group_id ************
  # check if request was already received
  def received_branch_request?(_user_group_id)
    user_group_branch_requests_received.pending.branch.where(user_group_from_id: _user_group_id).any?
  end

  # send a branch request to a main group
  def send_branch_request(_user_group_id, _current_user_id)
    req = user_group_branch_requests_sent.pending.branch.where(user_group_to_id: _user_group_id).first_or_initialize(user_id: _current_user_id)
    return req.errors.add(:base, 'Request already sent') if req.id
    req.save
    req
  end

  # accept a branch request to be a branch of current group
  def accept_branch_request(_branch_id)
    if received_branch_request? _branch_id
      user_group_branch_requests_received.pending.branch.where(user_group_from_id: _branch_id).take.accept!
      UserGroup.find(_branch_id).update(parent_id: id) # TODO verify it is was rejected or canceled
    else
      raise 'There is not exist a request to accept'
    end
  end

  # reject a branch request to be a branch of current group
  def reject_branch_request(_branch_id)
    if received_branch_request? _branch_id
      user_group_branch_requests_received.pending.branch.where(user_group_from_id: _branch_id).take.reject!
    else
      raise 'There is not exist a request to reject'
    end
  end

  # cancel a branch request to be a branch of current group
  def cancel_branch_request(_branch_id)
    if user_group_branch_requests_sent.pending.branch.where(user_group_to_id: _branch_id).any?
      user_group_branch_requests_sent.pending.branch.where(user_group_to_id: _branch_id).destroy_all
    else
      raise 'There is not exist a request to cancel'
    end
  end
  
  # exclude branch_id from branches list (makes _branch_id into main branch without parent branches)
  def exclude_branch(_branch_id)
    br = branches.find_by_id(_branch_id)
    if br
      br.update(parent_id: nil)
    else
      raise 'This branch does not exist'
    end
  end

  
  #********** requests to be a root group of _user_group_id ************
  # check if root branch already received from _user_group_id
  def received_root_branch_request?(_user_group_id)
    user_group_branch_requests_received.pending.root.where(user_group_from_id: _user_group_id).any?
  end

  # send a request to be a main group for _user_group_id
  def send_root_branch_request(_user_group_id, _current_user_id)
    user_group_branch_requests_sent.pending.root.where(user_group_to_id: _user_group_id).first_or_create(user_id: _current_user_id)
  end
  
    # accept a root request to be a main group of current group
  def accept_root_branch_request(_branch_id)
    if received_root_branch_request?(_branch_id)
      user_group_branch_requests_received.pending.root.where(user_group_from_id: _branch_id).take.accept!
      update(parent_id: _branch_id) # TODO verify it is was rejected or canceled
    else
      raise 'There is not exist a main church request to accept'
    end
  end
  
    # reject a root request to be a main group of current group
  def reject_root_branch_request(_branch_id)
    if received_root_branch_request?(_branch_id)
      user_group_branch_requests_received.pending.root.where(user_group_from_id: _branch_id).take.reject!
    else
      raise 'There is not exist a main church request to reject'
    end
  end
  
    # Cancel a root request to be a main group of current group
  def cancel_root_branch_request(_branch_id)
    if user_group_branch_requests_sent.pending.root.where(user_group_to_id: _branch_id).any?
      user_group_branch_requests_sent.pending.root.where(user_group_to_id: _branch_id).take.update(rejected_at: Time.current)
    else
      raise 'There is not exist a main church request to cancel'
    end
  end
  
    # current group is not anymore a root for _branch_id
  def cancel_root_branch
    update(parent_id: nil) # TODO remove requests
  end

  private
  # set default to pending for parent branch request status 
  def check_branch_request
    if request_root_branch.present?
      send_branch_request(request_root_branch, user_id)
    end
  end
end