class ContentDecorator < ApplicationDecorator
  delegate_all
  
  # return the daily devotion row widget
  #   block_right: content for right side
  #   block: extra content for main content
  def the_daily_devotion_row_widget(attrs = {}, &block)
    attrs = {qty_truncate: 50, block_right: '', class: ''}.merge(attrs)
    "<div class='media #{attrs[:class]}'>
      <div class='media-left text-center'>
        <div class='text-red'>#{object.publishing_at.strftime("%b") if object.publishing_at}</div>
        <div class='num'>#{object.publishing_at.strftime("%d") if object.publishing_at}</div>
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{object.title}
        </div>
        <div class='small text-gray'>
          #{object.summary(attrs[:qty_truncate])}
        </div>
        #{block ? h.capture(&block) : ''}
      </div>
      #{"<div class='media-right'>#{attrs[:block_right]}</div>" if attrs[:block_right].present?}
    </div>".html_safe
  end
  
  # render content in a media row item
  #   block_right: content for right side
  #   block: extra content for main content
  def the_row(attrs = {}, &block)
    attrs = {qty_truncate: 50, block_right: '', class: '', avatar_size: 60, search: false}.merge(attrs)
    "<div class='media #{attrs[:class]}'>
      <div class='media-left'>
        #{h.user_avatar_widget(object.user, attrs[:avatar_size], object.created_at)}
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{h.link_to (attrs[:search] ? object.try(:highlight).try(:title) || try(:highlight).try(:description) : object.the_title(attrs[:qty_truncate])), h.dashboard_content_path(object)}
        </div>
        <div class='small text-gray'>
          #{object.user.full_name(true, object.created_at)}
        </div>
        #{block ? h.capture(&block) : ''}
      </div>
      #{"<div class='media-right'>#{attrs[:block_right]}</div>" if attrs[:block_right].present?}
    </div>".html_safe
  end
  
  # return the full content body
  def the_body
    res = object.description.to_s.mask_mentions.mask_hashtags
    Rinku.auto_link(res, :all, 'target="_blank"')
  end
  
  # return widget body html content
  def the_widget_body
    if object.is_live_video?
      the_live_video
    end
  end
  
  # return the live video player panel
  def the_live_video
    live_video = object.try(:content_live_video)
    if live_video
      lnk = h.link_to '', live_video.video_url || live_video.screenshot.url, class: 'link_live_video', 'data-poster' => live_video.screenshot.url, 'data-player-callback' => 'ContentManager.live_video_player_settings'
      content = ''
      if live_video.video_url
        content = lnk
      else
        unless live_video.finished?
          token = get_live_video_token(live_video)
          content = "<div class='live_video_panel'><span class='live_span label label-primary'>Live</span> #{h.link_to '', live_video.hls_url, class: 'link_live_video opentok_player', 'data-token' => token, 'data-apikey' => ENV['OPENTOK_KEY'], 'data-session' =>live_video.session, 'data-autoplay' => true, 'data-player-callback' => 'ContentManager.live_video_player_settings', 'data-poster' => live_video.screenshot.url, 'data-type' => 'application/x-mpegurl'}</div>"
        else
          content = "<div class='awaiting_for_process'>
              <span class='live_span label label-default'>Preparing playback video</span>
              #{lnk}
            </div>"
        end
      end
      "<div data-callback='ContentManager.live_video_player' data-key='#{object.public_uid}' data-id='#{object.id}' class='hook_caller live_video_player_w'>
        <span class='qty_visits label label-default' data-qty='#{live_video.views_counter}'>#{h.humanize_number(live_video.views_counter)}</span>
        #{content}
      </div>".html_safe
    end
  end
  
  # generate and return a token for a live video of current content
  def get_live_video_token(live_video)
    h.session["livestreaming_video_player_#{live_video.id}"] ||= OpentokService.service.generate_token live_video.session
  end
  
  # return the summary for this content
  def the_excerpt(qty_words = 20)
    res = HTML_Truncator.truncate(object.description.to_s.mask_mentions.mask_hashtags, qty_words, ellipsis: '... ' << h.link_to('read more.', h.dashboard_content_path(object)))
    Rinku.auto_link(res, :all, 'target="_blank"') 
  end
end
