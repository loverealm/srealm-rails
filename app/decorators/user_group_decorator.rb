class UserGroupDecorator < ApplicationDecorator
  delegate_all
  
  # user group status button
  def the_status_btn(attrs = {})
    attrs = {class: ''}.merge attrs
    if object.is_in_group?(h.current_user.id)
      h.link_to 'Visit', h.dashboard_user_group_url(object), class: 'btn btn-primary ' << attrs[:class]
    elsif object.request_sent?(h.current_user.id)
      h.link_to 'Request Sent', 'javascript:void(0)', class: 'btn btn-primary disabled' << attrs[:class]
    else # join btn
      h.link_to 'Join', h.send_request_dashboard_user_group_url(object), class: 'btn btn-primary btn-bordered ujs_modal_success_replace ' << attrs[:class], remote: true, 'data-disable-with' => h.button_spinner('Joining...')
    end
  end

  # render user group in a media row item
  #   block_right: content for right side
  #   block: extra content for main content
  def the_row(attrs = {}, &block)
    attrs = {qty_truncate: 50, block_right: '', class: '', avatar_size: 60}.merge(attrs)
    "<div class='media #{attrs[:class]}'>
      <div class='media-left'>
        #{h.user_group_image_widget(object, attrs[:avatar_size])}
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{h.link_to object.name, h.dashboard_user_group_url(object)}
        </div>
        <div class='small text-gray'>
          <div class='descr'>#{object.the_description(attrs[:qty_truncate])}</div>
          <div class='small qty_members'>Members: #{h.humanize_number object.total_members}</div>
        </div>
        #{block ? h.capture(&block) : ''}
      </div>
      #{"<div class='media-right'>#{attrs[:block_right]}</div>" if attrs[:block_right].present?}
    </div>".html_safe
  end
  
  # return the payment link according the status
  def the_payment_link
    if object.is_verified?
      h.link_to '<b>Make Payment</b>'.html_safe, h.payment_options_dashboard_user_group_path(object), class: 'ujs_link_modal underline', remote: true, 'data-disable-with' => h.button_spinner('Loading...'), title: 'Make payment to church'
    elsif object.user_id == h.current_user.id
      "<div class='alert alert-danger skip_dismiss alert-xs'>#{h.link_to 'Verify group to start receiving payments', h.verify_dashboard_user_group_path(object), class: 'underline', remote: true, 'data-disable-with' => h.button_spinner}</div>".html_safe 
    else
      h.link_to 'Make Payment', '#', class: 'ujs_modal_inline underline bold', 'data-modal-title' => 'Make payment to church', 'data-content' => "This #{object.the_group_label} has not been set up to receive payments yet. You can ask its leaders to contact LoveRealm concerning this."
    end
  end
end
