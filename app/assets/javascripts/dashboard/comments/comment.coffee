class @Comment
  init: (@panel)->
    @readmore()
    @editable()
    @answerable()
    @destroyable()
    @likeable()
    @panel.on('update_body_content', @parse_body).trigger('update_body_content')
    
  init_answer: (panel)=>
    panel.on('update_body_content', @parse_body).trigger('update_body_content')
  
  parse_body: (e)=>
    $(e.currentTarget).find('.comment-body .the_content').stickerParse()
    
  readmore: =>
    @panel.on 'click', '.comment-body .read-more', (e)->
      $(this).closest('.summary').hide().next().removeClass('hidden')
      return false
      
  editable: =>
    @panel.on 'ajax:success', '.comment-body.editable form.edit_comment_form', (req, comment)->
      form = $(req.target)
      if form.is('form')
        FeedComments.update_comment(comment)
        form.hide().prevAll('.the_content').show()

    edit_form_checker = (p)->
      unless p.hasClass('added_form')
        p.addClass('added_form')
        is_answer = p.hasClass('comment-body-answer')
        field = p.next('textarea')
        form = $("""
          <form class="simple_form #{if is_answer then 'edit_answer_form' else 'edit_comment_form'}" action="#{field.attr('data-url')}" accept-charset="UTF-8" data-remote="true" method="post">
            <input type="hidden" name="_method" value="put">
            <div class="required comment_body"></div>
            <button name="button" type="submit" class="btn btn-default btn btn-primary btn-sm" data-disable-with="<i class='fa fa-spinner fa-spin'></i> Saving...">Save</button>
            <button name="button" type="button" class="btn btn-default btn btn-default btn-sm cancel">Cancel</button>
          </form>
        """)
        form.find('.comment_body').html(field.clone().removeClass('hidden'))
        field.replaceWith(form)
        form.validate()

    @panel.on 'edit', '.comment-body.editable > .the_content', (e)->
      unless $(e.target).is('a, a *')
        return if getSelectionText()
        edit_form_checker($(this))
        form = $(this).next('form')
        field = form.find('textarea')
        field.val(field.val().replace(/&gt;/g, '>').replace(/&lt;/g, '<'))
        h = field.val().length / 3
        field.height(if h > 60 then h else 60)
        form.removeClass('hidden').show()
        field.focus()
        $(this).hide()

    @panel.on('click', 'a.edit_comment_link', (e)=>
      e.preventDefault()
      $(e.target).closest('.comment-actions').nextAll('.editable').children('.the_content').trigger('edit')
    )

    @panel.on 'click', '.comment-body.editable form .cancel', (e)->
      $(this).closest('form').hide().prev().show()

  answerable: =>
    @panel.on 'click', '.comment-content .reply_comment', ->
      unless $(this).hasClass('form_added')
        $(this).addClass('form_added')
        FeedComments.answer_comment_form($(this).closest('.comment-content').find('.comment-body .comment-answers'), $(this).attr('href'))

      form = $(this).closest('.comment-content').find('.comment-body .comment-answers form.new_answer_comment').removeClass('hidden')
      if form.length
        $('body').animate({scrollTop: form.offset().top - 200});
        form.find('textarea').focus()
      return false

    @panel.on 'ajax:success', '.comment-body.editable form.edit_answer_form', (req, comment)->
      form = $(req.target)
      if form.is('form')
        FeedComments.update_comment(comment)
        form.hide().prevAll('.the_content').show()  
        
  destroyable: =>
    @panel.on 'ajax:success', '.del_comment', (e, qty)=>
      ContentManager.update_qty_comments($(e.target).closest('.content').attr('data-content-id'), parseInt(qty))

    @panel.on 'ajax:success', '.del_answer', (e, qty)=>
      ContentManager.update_qty_comments($(e.target).closest('.content').attr('data-content-id'), true)
      
  likeable: =>
    @panel.on 'click', '.comment-content .comment-like-action', ->
      link = $(this)
      like = !$(this).hasClass('active')
      counter = link.find('.comment_votes_count')
      if like
        counter.html(parseInt(counter.text()) + 1)
        link.addClass('active')
      else
        counter.html(parseInt(counter.text()) - 1)
        link.removeClass('active')
      $.post($(this).attr('href'), {like: like})
      return false    