class @FriendSuggestionsManager
  init: (@panel)->
    @is_widget = @panel.removeClass('overflow_hidden').hasClass('friends_suggestions_widget')
    @scrollEvents() if @is_widget
    @make_friends()
    @pending_friends()
    @closable()

  closable: ()=>
    @panel.find('.close_btn').click (e)->
      e.preventDefault()
      $(this).closest('.more_suggestions_block').remove()
    
  scrollEvents: ()=>
    # navigation events
    @panel.find('.list_items').bxSlider({
      minSlides: 3,
      maxSlides: 4,
      slideMargin: 2,
      slideWidth: 169,
      pager: false,
      infiniteLoop: false,
      hideControlOnEnd: true
    })
    
  make_friends: ()=>
    parent_class = if @is_widget then '.item_card' else '.media'
    @panel.on('ajax:success', '.become_friends', ()->
      link = $(this).prop('disabled', true).addClass('disabled')
      link.closest(parent_class).find('.btn-ignore').css('visibility', 'hidden')
      setTimeout(->
        link.html('Request Sent')
      , 100)
    )
    
    @panel.on('ajax:success', '.btn-ignore', ()->
      $(this).closest(parent_class).fadeOut()
    )
    
  # actions for pending friends  
  pending_friends: ()=>
    list = @panel.find('.pending-friends-list')
    return unless list.length
    list.on('ajax:success', '.btn-accept', ()->
      link = $(this).prop('disabled', true).addClass('disabled')
      link.closest('.media').find('.btn-reject').css('visibility', 'hidden')
      setTimeout(->
        link.html('Request Accepted')
      , 100)
    )

    @panel.on('ajax:success', '.btn-reject', ()->
      $(this).closest('.media').fadeOut()
    )
      