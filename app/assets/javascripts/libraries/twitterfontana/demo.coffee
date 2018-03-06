###
# Fontana Twitter authentication
###
@Fontana ?= {}
class @Fontana.TwitterAuth
  activeSession: (callback)->
    callback(null)
  signIn: (callback)->
  signOut: (callback)->
    
# Bootswatch stylesheets
styles =
    TwitterFontana:
        stylesheet: "/css/fontana.css"
        description: "TwitterFontana's default style"
    Bootstrap:
        stylesheet: ""
        description: "Just plain bootstrap"
    Amelia:
        stylesheet: "/bootstrap/amelia/bootstrap.min.css"
        description: "Sweet and cheery"
    Cerulean:
        stylesheet: "/bootstrap/cerulean/bootstrap.min.css"
        description: "A calm blue sky"
    Cosmo:
        stylesheet: "/bootstrap/cosmo/bootstrap.min.css"
        description: "An ode to Metro"
    Cyborg:
        stylesheet: "/bootstrap/cyborg/bootstrap.min.css"
        description: "Jet black and electric blue"
    Flatly:
        stylesheet: "/bootstrap/flatly/bootstrap.min.css"
        description: "Flat and modern"
    Journal:
        stylesheet: "/bootstrap/journal/bootstrap.min.css"
        description: "Crisp like a new sheet of paper"
    Readable:
        stylesheet: "/bootstrap/readable/bootstrap.min.css"
        description: "Optimized for legibility"
    Simplex:
        stylesheet: "/bootstrap/simplex/bootstrap.min.css"
        description: "Mini and minimalist"
    Slate:
        stylesheet: "/bootstrap/slate/bootstrap.min.css"
        description: "Shades of gunmetal gray"
    Spacelab:
        stylesheet: "/bootstrap/spacelab/bootstrap.min.css"
        description: "Silvery and sleek"
    United:
        stylesheet: "/bootstrap/united/bootstrap.min.css"
        description: "Ubuntu orange and unique font"

transitions =
    "Compress": "compress"
    "Fade-In": "fade-in"
    "Hinge": "hinge"
    "Lightspeed": "lightspeed"
    "Scroll-Down": "scroll-down"
    "Scroll-Up": "scroll-up"
    "Slide": "slide"
    "Tilt-Scroll": "tilt-scroll"
    "Vertigo": "vertigo"
    "Zoom-In": "zoom-in"

# Tying things together to make the demo page work
$ ->
  panel = $('#live_board')
  window['TWITTER_SETTINGS'] = {listUrlBase: 'http://owen.com1/', cashtagUrlBase: 'http://owen.com2/', hashtagUrlBase: panel.attr('data-hashtag-url')}
  controls = $("#controls")
  signIn = $("#signin")
  signOut = $("#signout")
  auth = new Fontana.TwitterAuth()
  container = $(".fontana")
  visualizer = null
  settings = null
  
  fetchSettings = ->
  
  rigSearchBox = (settings)->
      input = $("#search", settings)
      if $(document.body).hasClass("signedIn")
          input.attr("disabled", false)
          input.keypress (e) ->
              if(e.which == 13)
                  e.preventDefault()
                  input.change()
                  return false
          input.change ->
              q = $("#search", settings).val()
              if q && q != visualizer.datasource.q
                  twitterFontana(transition: $("#transition", settings).val(),
                                 $("#search", settings).val())
      else
          input.attr("disabled", true)
  
  rigStyleSwitch = (settings)->
  
  rigTransitionSwitch = (settings)->
      select = $("#transition", settings)
      Object.keys(transitions).forEach (key) ->
          transition = transitions[key]
          select.append("<option value='#{transition}'>#{key}</option>")
      select.change (e)->
          transition = $(e.target).val()
          visualizer.pause()
          visualizer.config(transition: transition)
          visualizer.resume()
  
  # Toggles
  toggleSettings = ->
      if !settings
          fetchSettings()
      else
          settings.toggle()
  
  toggleViz = ->
      icon = $("[class*='icon-']", this)
      if visualizer.paused
          icon.removeClass("icon-play")
          icon.addClass("icon-pause")
          visualizer.resume()
      else
          icon.removeClass("icon-pause")
          icon.addClass("icon-play")
          visualizer.pause()
  
  toggleFullscreen = ->
      if Fontana.utils.isFullScreen()
          Fontana.utils.cancelFullScreen()
      else
          Fontana.utils.requestFullScreen(document.body)
  
  # Auth
  checkSession = ->
      auth.activeSession (data)->
          if (data)
              isSignedIn(data)
          else
              isSignedOut()
  
  isSignedIn = (data)->
      $(document.body).addClass('signedIn')
      userText = $(".navbar-text", signOut)
      userText.html(nano(userText.data("text"), data))
      signIn.addClass("hidden")
      signOut.removeClass("hidden")
      if settings
          rigSearchBox(settings)
          twitterFontana(transition: $("#transition", settings).val(),
                         $("#search", settings).val())
      else
          twitterFontana()
  
  isSignedOut = ->
      $(document.body).removeClass('signedIn')
      signIn.removeClass("hidden")
      signOut.addClass("hidden")
      if settings
          rigSearchBox(settings)
          HTMLFontana(transition: $("#transition", settings).val())
      else
          HTMLFontana()
  
  # Two Demo Fontanas
  twitterFontana = (settings={}, q="TwitterFontana")-> # not used
      if visualizer
          visualizer.stop()
      datasource = new Fontana.datasources.TwitterSearch(q)
      visualizer = new Fontana.Visualizer(container, datasource)
      visualizer.start(settings)
  
  HTMLFontana = (settings={})->
      if visualizer
        visualizer.stop()
      if not settings.transition
        settings.transition = Fontana.Visualizer.transitionEffects[5] #4
      visualizer = new Fontana.Visualizer(container, HTMLFontana.datasource)
      window['main_visualizer'] = visualizer
      visualizer.start(settings)
      new RealTimeManager(panel.attr('data-hash-tag'), panel, visualizer)
      
  # Prepare our datasource, the messages will disappear soon...
  HTMLFontana.datasource = new Fontana.datasources.HTML(container)
  HTMLFontana.datasource.getMessages()
  
  # Bindings
  $(".settings", controls).click -> toggleSettings.call(this)
  $(".pause-resume", controls).click -> toggleViz.call(this)
  $(".fullscreen", controls).click -> toggleFullscreen.call(this)
  $("button", signIn).click -> auth.signIn(checkSession)
  $("button", signOut).click -> auth.signOut(checkSession)
  $("#logos .close").click -> $(this).parent().remove()
  $(".zoom_plus_btn", controls).click ->
    $('#zoom_style').html(".lead{font-size: "+(parseInt($('.lead:first').css('font-size')) + 10)+"px;}")
  $(".zoom_minus_btn", controls).click ->
    $('#zoom_style').html(".lead{font-size: "+(parseInt($('.lead:first').css('font-size')) - 10)+"px;}")

  setTimeout(->
    $('#live_board > .message:first').css('opacity', 1) if $('#live_board > .message').length == 1
  , 1000)
    
  
  checkSession()
  
class @RealTimeManager
  constructor: (@hash_tag, @panel, @visualizer)->
    @loadInitialValues()
    @initListener()
  
  loadInitialValues: =>
    @visualizer.renderMessages($.map(INITIAL_CONTENTS, (obj)->
        obj['created_at'] = new Date(obj['created_at']).toString()
        return obj
      )
    )

  initListener: =>
    @qty = 1
    pubnubDemo.addListener({
      message: (channel_message)=>
        message = JSON.parse(channel_message.message)
        data = message.data
        if data.type == 'hashtag_' + @hash_tag
          content = data.source
          user = data.user
          @visualizer.renderMessages([{
            id: 'inline_content'+(content.id || @qty += 1), 
            created_at: new Date(content.created_at * 1000).toString(),
            text: content.description + "Added - " + @qty,
            user: {
              screen_name: user.mention_key,
              name: user.full_name,
              profile_image_url: user.avatar_url
            }
          }])
    })
    pubnubDemo.subscribe({
      channels: ['/notifications/' + $('meta[name=commonHash]').attr("content")]
    })