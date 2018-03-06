class PromotionDecorator < ApplicationDecorator
  delegate_all

  # return the daily devotion row widget
  #   block_right: content for right side
  #   block: extra content for main content
  def the_banner_widget(attrs = {}, &block)
    attrs = {qty_truncate: 100, block_right: '', class: ''}.merge(attrs)
    return object.promotable.decorate.the_widget(attrs) if is_event?
    "<a class='display-blocks #{attrs[:class]} no_hover' href='#{object.website || h.dashboard_user_group_path(id: object.promotable_id)}' target='_blank'>
      <span class='overflow_hidden' style='max-height: 150px; margin-bottom: 10px;'>
        <img style='min-width: 100%; max-width: none;' src='#{object.promotable.image.url}'>
      </span>
      <span class='caption'>
        <span class='bold'>#{object.promotable.name}</span>     
        <span class='small text-gray'>#{object.promotable.the_description(attrs[:qty_truncate])}</span>   
      </span>
    </a>".html_safe
  end
  
  def is_event?
    object.promotable_type == 'Event'
  end
end