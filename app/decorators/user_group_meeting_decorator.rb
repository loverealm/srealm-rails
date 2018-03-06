class UserGroupMeetingDecorator < ApplicationDecorator
  delegate_all

  # return the daily devotion row widget
  #   block_right: content for right side
  #   block: extra content for main content
  def the_widget(attrs = {}, &block)
    attrs = {qty_truncate: 100, block_right: '', class: ''}.merge(attrs)
    "<div class='media #{attrs[:class]}'>
      <div class='media-left text-center'>
        <div class='text-red'>#{object.day}</div>
        <div class='num'>#{object.hour}</div>
      </div>
      <div class='media-body'>
        <div class='media-heading text-gray'>
          #{object.title}
        </div>
        #{block ? h.capture(&block) : ''}
      </div>
      #{"<div class='media-right'>#{attrs[:media_right]}</div>" if attrs[:media_right]}
    </div>".html_safe
  end
end

