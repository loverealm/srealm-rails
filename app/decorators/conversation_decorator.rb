class ConversationDecorator < ApplicationDecorator
  delegate_all
  
  # return the other participant for single conversations
  def other_participant
    @_cache_other_participant ||= object.user_participants.where.not(id: current_user.id).first.try(:decorate)
  end

  # return the conversation's title according the kind: single or group
  def the_title
    if object.is_group_conversation?
      object.group_title
    else
      other_participant.try(:full_name, false, :now) || "Anonymous"
    end
  end

  # return the conversation's image according the kind: single or group
  def the_image
    if object.is_group_conversation?
      object.image.url
    else
      participant = other_participant
      Rails.logger.info "Error: #{object.inspect}" unless participant.present?
      participant.avatar_url(:now)
    end
  end
  
  # makes conversation row widget with last message
  def conversation_row_widget(settings = {}, &block)
    settings = {thumb_size: 30, class: ''}.merge(settings)
    message = object.messages.recent.first
    if object.is_group_conversation?
      avatar = "#{h.image_tag(the_image, class: 'media-object img-responsive avatar_image', style: "#{"width: #{settings[:thumb_size]}px; height: #{settings[:thumb_size]}px; min-width: #{settings[:thumb_size]}px;"}")}
                #{"<div class='qty_users text-tiny small text-center'>#{object.qty_members} users</div>" }"
    else
      avatar = h.user_avatar_widget(other_participant, settings[:thumb_size], :now, include_status: true)
    end
    "<div data-unread='#{object.count_pending_messages_for(h.current_user)}' data-id='#{object.id}' data-callback='chat_box:init_conversation_hook_item' class='hook_caller conversation-item media #{settings[:class]}'>
      <div class='media-left'>
        #{avatar}
      </div>
      <div class='media-body'>
        <div class='row'>
          <div class='padding_right0 col-xs-8 ellipsis c_title'>#{the_title}</div>
          <div class='timestamp col-xs-4 small ellipsis text-right'> #{message.try(:the_created_at)}</div>
        </div>
        #{(block ? h.capture(&block) : '')}
        <div class='last-message small text-gray'>
          <span class='ellipsis'>#{message.try(:the_text_body)}</span>
        </div>
      </div>
    </div>".html_safe
  end

  # return public conversation row widget
  #   conversation: Conversation Model
  #   settings: {thumb_size: 60, class: '', media_left: '', media_right: ''}
  def public_conversation_row_widget(settings = {}, &block)
    settings = {thumb_size: 30, class: '', media_left: '', media_right: '', image_class: ''}.merge(settings)
    "<div data-unread='#{object.count_pending_messages_for(h.current_user)}' data-id='#{object.id}' data-callback='chat_box:init_conversation_hook_item' class='hook_caller public_group media #{settings[:class]}' data-in_group='#{object.is_in_conversation?(h.current_user.id)}'>
      <div class='media-left post_relative'>
        #{h.image_tag(the_image, alt: settings[:alt], class: 'media-object img-responsive avatar_image' << settings[:image_class], style: "#{"width: #{settings[:thumb_size]}px; height: #{settings[:thumb_size]}px; min-width: #{settings[:thumb_size]}px;"}")}
        #{settings[:media_left]}
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{the_title}
        </div>
        #{(block ? h.capture(&block) : '')}
      </div>
      #{ "<div class='media-right'>#{settings[:media_right]}</div>" if settings[:media_right].present? }
    </div>".html_safe
  end
end
