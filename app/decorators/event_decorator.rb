class EventDecorator < ApplicationDecorator
  delegate_all

  # return the daily devotion row widget
  #   block_right: content for right side
  #   block: extra content for main content
  def the_widget(attrs = {}, &block)
    attrs = {qty_truncate: 100, block_right: '', attend_right: true, class: '', photo: false}.merge(attrs)
    photo = ''
    photo = "<div class='overflow_hidden' style='max-height: 145px; margin-bottom: 10px;'><img style='min-width: 100%; max-width: none;' src='#{object.photo.url}'></div>" if attrs[:photo]
    link = the_attend_link
    
    "<form class='#{attrs[:class]} media ujs_block_loading ujs_link_modal cursor_pointer event_media_item' action='#{the_url}' data-remote='true' onclick=\"if(!$(window.event.target).is('a')) $(this).submit();\" data-modal-title='Event Details'>
      #{photo}
      <div class='media-left text-center nowrap'>
        <div class='text-red'>#{object.start_at.strftime("%b") if object.start_at}</div>
        <div class='num'>#{object.start_at.strftime("%d") if object.start_at}</div>
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{object.name}
        </div>
        <div class='small text-gray'>
          #{object.description.truncate(attrs[:qty_truncate])}
          <div class='p_attending'>#{the_attending}</div>
        </div>
        #{block ? h.capture(&block) : ''}
        #{"<div class='text-center margin_top5'>#{link}</div>" unless attrs[:attend_right]}
      </div>
      <div class='media-right'>
        #{link if attrs[:attend_right]}
        #{attrs[:block_right]}
      </div>
    </form>".html_safe
  end
  
  def the_attending
    h.content_tag :span, class: 'text-xs text-gray underline' do
      qty = object.qty_attending
      text = ''
      return '' if qty == 0
      if object.is_attending?(h.current_user.id)
        qty -= 1
        text += 'You'
        text += "#{qty <= 0 ? ' are attending' : "#{qty == 1 ? ' and 1 user are attending' : " and #{qty} users are attending"}"}"
      else
        text = qty == 1 ? '1 user is attending' : " #{qty} users are attending"
      end
      text
    end
  end
  
  def the_url(extra_params = {})
    h.dashboard_user_group_event_path({user_group_id: object.eventable_id, id: object}.merge(extra_params))
  end
  
  # return the link to redeem a ticket for this event
  def the_attend_link
    return '' unless h.can? :buy_ticket, object
    return '' if object.is_attending?(h.current_user.id)
    if object.is_free?
      h.link_to('Attend', h.attend_dashboard_user_group_event_path(user_group_id: object.eventable_id, id: object), class: 'btn btn-primary btn-bordered btn-sm ujs_success_replace', remote: true, 'data-disable-with' => h.button_spinner)
    else
      h.link_to("Buy Ticket (#{h.number_to_currency(object.price)})", the_url(include_payment: true), class: 'btn btn-primary btn-bordered btn-sm ujs_link_modal', remote: true, 'data-disable-with' => h.button_spinner, 'data-modal-title' => 'Buy Ticket')
    end
  end
end

