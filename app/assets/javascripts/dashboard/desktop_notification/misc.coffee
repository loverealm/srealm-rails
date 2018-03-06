# shows a desktop messages if it is enabled
window['_desktop_push_notification_cache'] = []
class @DesktopMessage
  # check setting params in https://pushjs.org/docs/quick-start
  # @param title: (String) notification title
  # @param settings: {
  #    body: "How's it hangin'?",
  #    icon: '/icon.png',
  #    timeout: 4000,
  #    onClick: function () {
  #      window.focus();
  #      this.close();
  #  }
  @notify: (title, settings) ->
    if title && Push.Permission.has()
      settings = $.extend({icon: $('head link[type="image/x-icon"]').attr('href'), timeout: 6000}, settings || {})
      _cache = "#{title}#{settings['body']}"
      return if $.inArray(_cache, window['_desktop_push_notification_cache']) >= 0
      setTimeout((-> window['_desktop_push_notification_cache'].delete(_cache)), settings.timeout)
      window['_desktop_push_notification_cache'].push(_cache)
      Push.create(title, settings)
      
  # check if current browser has desktop permissions
  @check_permission_status: ->
    unless Cookies.get('desktop_notification')
      return if Push.Permission.get() == 'denied'
      unless Push.Permission.has()
        message = $("""
          <div class="alert alert-warning skip_dismiss" style='margin-top: -15px'>
            <i class="fa fa-bell close fa-2x"></i>
            <p>
              We strongly recommend enabling desktop notifications if you’ll be using Loverealm on this computer.
            <p>
            <div>
              <a href='#' class='enable'>Enable notifications</a> •
              <a href='#' class='next'>Ask me next time</a> •
              <a href='#' class='never'>Never ask again on this computer</a>
            </div>
          </div>
        """)
  
        $('#main_container').prepend(message)
        message.find('.enable').click(->
          Push.Permission.request((->message.fadeOut()), ->);
        )
  
        message.find('.next').click(->
          message.fadeOut()
          Cookies.set('desktop_notification', true, {expires: 7})
        )
  
        message.find('.never').click(->
          message.fadeOut()
          Cookies.set('desktop_notification', true, {expires: 99999})
        )
      
if window['CURRENT_USER'] && $('body').hasClass('news_feed')
  $ -> DesktopMessage.check_permission_status()