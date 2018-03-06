module Admin::ApplicationHelper
  # render html link to user profile using ID
  def user_link_by_id(id)
    user = User.find(id)
    link_to user.full_name(false), dashboard_profile_path(id: user), target: '_blank'
  end
  
  # creates restore link for watchdog and administrators according their permissions
  def watchdog_restore_link(ele, action_name)
    res = ""
    res << content_tag(:li, link_to('See details', url_for(action: :show, id: ele), class: ' ujs_link_modal', remote: true, 'data-disable-with' => button_spinner, 'data-modal-title' => 'Action Details'))
    res << content_tag(:li, link_to('Confirm Action', url_for(action: :confirm, id: ele.id, kind: 'confirm'), method: :post, class: '', 'data-confirm' => 'Are you sure you want to confirm this action?')) if can?(:confirm, ele)
    res << content_tag(:li, link_to('Cancel Action', url_for(action: action_name, id: ele.id, kind: 'cancel'), class: '', 'data-confirm' => 'Are you sure you want to cancel this action?', method: :post)) if can?(:cancel, ele)
    res << content_tag(:li, link_to('Restore Action', url_for(action: action_name, id: ele.id), class: "ujs_link_modal ", remote: true, method: :get, 'data-disable-with' => button_spinner, 'data-modal-title' => 'Restore Action', 'data-modal-confirm' => "Are you sure you want to restore this action?")) if can?(:restore, ele)
    dropdown_builder right: true, button_class: 'btn-xs' do
      res.html_safe
    end
  end
end