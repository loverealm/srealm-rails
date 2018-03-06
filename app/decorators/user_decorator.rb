class UserDecorator < ApplicationDecorator
  delegate_all

  # return the devotion for today, if it doesn't exist will return the last devotion
  def the_current_devotion
    Rails.cache.fetch("current_devotion_#{Date.today.to_s}_#{Rails.cache.read('current_devotion_reset_at')}_#{object.id}", expires_in: Time.current.end_of_day) do
      Content.current_devotion(object.user_groups.first.try(:id))
    end
  end

  # return the label for today daily devotion
  def the_daily_inspiration_label
    Setting.get_setting('daily_inspiration_label').gsub('%{title}', the_current_devotion.try(:title))
  end
  
  def the_suggested_promotions
    Promotion.active.order('random()')
  end
  
  # generate send request link from current_user to other_user
  #   attrs: {class: '', label: ''}
  def the_friend_request_link(other_user_id, attrs = {})
    attrs = {label: 'Become Friends', class: ''}.merge(attrs)
    h.link_to attrs[:label], h.send_friend_request_dashboard_users_path(user_id: other_user_id), class: "btn btn-primary become_friends #{attrs[:class]} ujs_success_replace", remote: true, method: :post, 'data-disable-with' => h.button_spinner('Sending...')
  end

  # prints the friend relationship status 
  #   attrs: {class: '', label: '', time: nil} ==> class: btn extra custom class
  def the_friend_status_for(_user, attrs = {})
    _user = _user.is_a?(User) ? _user : User.find(_user)
    return '' if attrs[:time] && _user.was_anonymity?(attrs[:time])
    attrs = {class: ''}.merge(attrs)
    res = case object.friend_status(_user.id)
      when ''
        the_friend_request_link(_user.id, attrs)
      when 'pending'
        '<span class="label label-default '+attrs[:class]+'">Pending</span>'
      when 'sent'
        '<span class="label label-default '+attrs[:class]+'">Request Sent</span>'
      when 'friends'
        #'<span class="label label-default '+attrs[:class]+'">Friends</span>'
        ''
      when 'rejected'
        '<span class="label label-default '+attrs[:class]+'">Rejected</span>'
      end
    res.html_safe
  end

  def the_mentor_chat_link(attrs = {})
    attrs = {class: 'btn  btn-primary', label: "Let's Talk", extra_class: ''}.merge(attrs)
    h.link_to attrs[:label], h.start_conversation_dashboard_conversations_path(user_id: object.id), class: "#{attrs[:class]} #{attrs[:extra_class]} ujs_start_conversation ", remote: true, 'data-disable-with' => h.button_spinner
  end

  def the_mentor_set_default_link(attrs = {})
    attrs = {class: 'btn  btn-black', label: 'Set as default counselor', extra_class: ''}.merge(attrs)
    h.link_to(attrs[:label], h.set_default_dashboard_counselor_path(id: object.id), class: "#{attrs[:class]} #{attrs[:extra_class]}")
  end
  
  def the_mentor_video_link(attrs = {})
    attrs = {class: 'btn  btn-primary', label: 'Book Appointment', extra_class: ''}.merge(attrs)
    h.link_to(attrs[:label], h.new_dashboard_appointment_path(counselor_id: object.id), class: "#{attrs[:class]} #{attrs[:extra_class]} ujs_link_modal", remote: true, 'data-disable-with' => h.button_spinner)
  end
  
  # render mentor row item html, attrs: class. thumb_size, truncate, btns_position (right, bottom), kind: false/true
  def the_mentor_row_item(attrs = {}, &block)
    attrs = {class: '', thumb_size: 60, truncate: 60, block_position: 'right', show_text_status: true, user_link_class: '', kind: false}.merge(attrs)
    "<div class='media media_bordered #{attrs[:class]}'>
      <div class='media-left'>
        #{h.user_avatar_widget(object, attrs[:thumb_size], nil, {include_status: true}) }
      </div>
      <div class='media-body'>
        <div>#{h.link_to_user(object, class: "#{attrs[:user_link_class]}")}</div>
        #{"<div class='text-gray small'>#{the_kind}</div>" if attrs[:kind]}
        <div class='descr'>#{object.the_biography(attrs[:truncate])}</div>
        #{"<div class='status'><b>#{object.online? ? 'Available' : 'Reachable'}</b></div>" if attrs[:show_text_status]}
        #{attrs[:block_position] == 'bottom' ? (block ? h.capture(&block) : '') : ''}
      </div>
      #{"<div class='media-right'>#{(block ? h.capture(&block) : '')}</div>" if attrs[:block_position] == 'right'}
    </div>".html_safe
  end

  # render mentor row item html, attrs: class. thumb_size, truncate, btns_position (right, bottom), kind: false/true
  def the_row(attrs = {}, &block)
    attrs = {include_status: false, class: '', thumb_size: 60, truncate: 60, block_position: 'right', show_text_status: true, user_link_class: '', kind: false}.merge(attrs)
    "<div class='media #{attrs[:class]}'>
      <div class='media-left'>
        #{h.user_avatar_widget(object, attrs[:thumb_size], nil, {include_status: attrs[:include_status]}) }
      </div>
      <div class='media-body'>
        <div>#{h.link_to_user(object, class: "#{attrs[:user_link_class]}")}</div>
        <div class='descr'>#{object.the_biography(attrs[:truncate])}</div>
    #{attrs[:block_position] == 'bottom' ? (block ? h.capture(&block) : '') : ''}
      </div>
      #{"<div class='media-right'>#{(block ? h.capture(&block) : '')}</div>" if attrs[:block_position] == 'right'}
    </div>".html_safe
  end

  def the_follow_link(attrs = {})
    attrs = {class: 'btn  btn-default', label: 'Follow', extra_class: '', ujs_expression: ''}.merge(attrs)
    h.link_to attrs[:label], h.follow_user_dashboard_users_path(user_id: object.id), remote: true, class: "ujs_success_hide #{attrs[:extra_class]} #{attrs[:class]}", 'data-disable-with' => h.button_spinner, 'data-ujs-expression' => attrs[:ujs_expression]
  end

  # @param attrs:
  #   success_remove: (String) javascript closest item which will be removed on ajax link success (default empty)
  def the_cancel_follow_link(attrs = {})
    attrs = {class: 'btn  btn-default', success_remove: '', label: 'Cancel', extra_class: '', ujs_expression: ''}.merge(attrs)
    h.link_to attrs[:label], h.cancel_follow_suggestion_dashboard_users_path(user_id: object.id), remote: true, class: "ujs_success_remove #{attrs[:extra_class]} #{attrs[:class]}", 'data-closest-remove' => attrs[:success_remove], 'data-disable-with' => h.button_spinner, 'ujs-expression' => attrs[:ujs_expression]
  end

  def the_unfollow_link(attrs = {})
    attrs = {class: 'btn  btn-black', label: 'Follow', extra_class: ''}.merge(attrs)
    h.link_to 'Unfollow', h.unfollow_user_dashboard_users_path(user_id: object.id), remote: true, class: "ujs_success_hide #{attrs[:extra_class]} #{attrs[:class]}", 'data-disable-with' => h.button_spinner
  end
  
  # prints current user's session status
  def the_online_status
    "<span class='avatar_status glyphicon #{'online' if object.online?} hook_caller' data-id='#{object.id}' data-callback='User:online_checked'></span>".html_safe
  end
  
  def the_edit_avatar_form(attrs = {})
    attrs = {class: '', label: 'Edit', style: '', btn_class: 'btn-default btn-xs'}.merge(attrs)
    h.form_for(object, url: h.profile_avatar_dashboard_users_path, multipart: true, method: :put, remote: true, html: { class: 'btn-hover-item reset_on_success ujs_filestyle ' << attrs[:class], style: attrs[:style], 'data-disable-with' => h.button_spinner('Uploading...') }) do |f|
      f.file_field :avatar, required: true, class: 'filestyle', 'data-buttonText' => attrs[:label], 'data-buttonBefore'=> true, 'data-buttonName' => attrs[:btn_class], 'data-icon' => false, 'data-input'=>'false', 'onChange'=>'$(this).closest(\'form\').submit();', 'data-badge'=>'false', accept: 'image/gif,image/jpeg,image/png,image/jpg'
    end
  end
  
  def the_edit_cover_form(attrs = {})
    attrs = {class: '', label: 'Edit', style: ''}.merge(attrs)
    h.form_for(object, url: h.profile_cover_dashboard_users_path, multipart: true, method: :put, remote: true, html: { class: 'btn-hover-item reset_on_success ujs_filestyle ' << attrs[:class], style: attrs[:style], 'data-disable-with' => h.button_spinner('Uploading...') }) do |f|
      f.file_field :cover, required: true, class: 'filestyle', 'data-buttonText' => attrs[:label], 'data-buttonBefore'=> true, 'data-buttonName' => 'btn-default btn-xs', 'data-icon' => false, 'data-input'=>'false', 'onChange'=>'$(this).closest(\'form\').submit();', 'data-badge'=>'false', accept: 'image/gif,image/jpeg,image/png,image/jpg'
    end
  end
  
  def the_kind
    object.is_official_mentor? ? 'Official Mentor' : 'Other Mentor'
  end
  
  # return greeting arts
  def the_greeting_arts
    b_label = Setting.happy_birthday_for(object)
    data = {
        arts:{
            afternoon_art: Setting.get_setting("#{object.country}_good_afternoon_art_country") || Setting.get_setting(:good_afternoon_art),
            morning_art: Setting.get_setting("#{object.country}_good_morning_art_country") || Setting.get_setting(:good_morning_art),
            evening_art: Setting.get_setting("#{object.country}_good_night_art_country") || Setting.get_setting(:good_night_art),
            birthday_art: b_label.present? ? Setting.get_setting("#{object.country}_happy_birthday_art_country") || Setting.get_setting(:happy_birthday_art) : '',
        },
        labels: {
            morning: Setting.greeting_label(object),
            afternoon: Setting.greeting_label(object, 'afternoon'),
            evening: Setting.greeting_label(object, 'night'),
            birthday: b_label,
        },
        daily_inspiration: {
            label: the_daily_inspiration_label,
            id: the_current_devotion.try(:id)
        },
        colors: {
            title: {
                morning: Setting.greeting_color('morning', 'title'),
                afternoon: Setting.greeting_color('afternoon', 'title'),
                evening: Setting.greeting_color('night', 'title')
            },
            text: {
                morning: Setting.greeting_color('morning'),
                afternoon: Setting.greeting_color('afternoon'),
                evening: Setting.greeting_color('night'),
                birthday: '#ffffff'
            }
        }
    }
    Rails.cache.fetch("welcome_greeting_art_#{object.id}") do
      if object.created_at >= 8.hours.ago
        data[:arts][:welcome] = Setting.get_setting(:welcome_art)
        data[:labels][:welcome] = Setting.welcome_label(object)
        data[:colors][:text][:welcome] = '#ffffff'
      end
    end
    data
  end
  
end
