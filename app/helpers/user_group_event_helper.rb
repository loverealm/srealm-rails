module UserGroupEventHelper
  # create event row item widget
  def event_row_widget(event, settings = {}, &block)
    settings = {class: ''}.merge(settings)
    "<div class='media no_overflow #{settings[:class]}'>
      <div class='media-left text-center'>
        <div class='text-red'>#{event.start_at.strftime("%b")}</div>
        <div class='num'>#{event.start_at.strftime("%d")}</div>
      </div>
      <div class='media-body'>
        <div class='media-heading'>
          #{event.name}
        </div>
        <div class='small text-gray'>
          #{event.excerpt(100)}
        </div>
      </div>
      <div class='media-right'>
        #{block ? capture(&block) : ''}
      </div>
    </div>".html_safe
  end
end