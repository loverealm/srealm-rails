$ ->
  # feed editor customization
  $.extend($.summernote.plugins, {
    'feedMode': (context)->
      ui = $.summernote.ui;
      @.events = {
        'summernote.init': (we, e)->
          # e.statusbar.hide()
          e.toolbar.before(e.editingArea)
          e.toolbar.addClass('text-right').find('.btn').removeClass('btn-default')
          e.toolbar.find('.note-icon-picture').parent().html('Image').addClass('btn-picture').attr('data-disable-with', "<i class='fa fa-spinner fa-spin'></i> Uploading...")
          e.toolbar.find('.note-btn-italic').html('<i>i</i>')
          e.toolbar.find('.note-btn-bold').html('<b>B</b>')
          e.toolbar.find('.note-icon-link').parent().html('Link')
          e.toolbar.find('.dropdown-style').prev().html('Tt').end().children().children().slice(0, 3).remove()
          # e.toolbar.find('.btn-picture').attr('data-disable-with', "<i class='fa fa-spinner fa-spin'></i> Uploading...")
          
      }
      return @
  });

  # bible quotation
  $.extend($.summernote.plugins, {
    'bible': (context)->
      self = this;
      ui = $.summernote.ui;
      context.memo('button.bible', ()->
        button = ui.button({
          contents: 'Bible',
          tooltip: 'Bible Passage',
          data: {'disable-with': "<i class='fa fa-spinner fa-spin'></i> Loading..."},
          click: ()->
            btn = $(this)
            add_events = (modal)->
              current_book = null
              form = modal.find('form')
              books = "<option>Select a book</option>"
              for book in window['BIBLE_BOOKS']
                books += "<option value='#{book.book_id}'>#{book.book_name}</option>"
              chapters_sel = modal.find('.chapters')
              books_sel = modal.find('.books').html(books).change(->
                current_book = (window['BIBLE_BOOKS'].filter (i) -> i.book_id is books_sel.val())[0]
                chapters_sel.html('')
                if current_book
                  counter = 1
                  chapters_options = ""
                  while counter <= current_book.chapters
                    chapters_options += "<option value='#{counter}'>#{counter}</option>"
                    counter += 1
                  chapters_sel.html(chapters_options)
                chapters_sel.trigger('change')
              )
              chapters_sel.change(->
                $.rails.disableFormElement(form.find('.btn'))
                $.get("/dashboard/bible/#{books_sel.val()}/#{$(this).val()}/verses", (qty_verses)-> 
                  modal.find('.verse1').attr('data-rule-max', qty_verses)
                  modal.find('.verse2').attr('data-rule-max', qty_verses)
                  $.rails.enableFormElement(form.find('.btn'))
                )
              )

              form.submit(->
                return false unless form.valid()
                chapter = chapters_sel.val()
                ver2 = modal.find('.verse2').val()
                verses = modal.find('.verse1').val() + (if ver2 then "-"+ver2 else '')
                $.rails.disableFormElement(form.find('.btn'))
                $.get("/dashboard/bible/passage/#{books_sel.val()}-#{chapter}:#{verses}", (res_verse)->
                  context.invoke('editor.restoreRange')
                  context.invoke('editor.insertNode', $(res_verse || '<span></span>')[0])
                  modal.modal('hide')
                ).complete(->
                  $.rails.enableFormElement(form.find('.btn'))
                )
                return false
              ).validate()
            
            render_view = ->
              context.invoke('editor.saveRange');
              content = """
                <form>
                  <div class='form-group'>
                    <label>Book</label>
                    <select class='required books form-control'></select>
                  </div>
                  <div class='form-group'>
                    <label>Chapter</label>
                    <select class='required chapters form-control'></select>
                  </div>
                  <div class='form-group'>
                    <div class="input-group">
                      <input class="form-control required verse1" id='modal_bidle_verse_1' data-rule-min='1' placeholder="Verse" type='number'>
                      <span class="input-group-addon">To</span> 
                      <input class="form-control verse2" placeholder="Verse" data-rule-min='1' type='number' data-rule-greater_than='#modal_bidle_verse_1'>
                    </div>
                  </div>
                  <div class='form-group'>
                    <button type='submit' class='btn btn-primary' data-disable-with='<i class="fa fa-spinner fa-spin"></i> Loading...'>Submit Passage</button>
                  </div>
                </form>
              """
              modal = modal_tpl({id: 'editor_modal_bible', title: 'Enter Quotation', content: content})
              modal.modal()
              add_events(modal)
              
            unless window['BIBLE_BOOKS']
              $.rails.disableFormElement(btn)
              $.getJSON('/dashboard/bible/books', (books)->
                window['BIBLE_BOOKS'] = books
                $.rails.enableFormElement(btn)
                render_view()
              )
            else
              render_view()
              
        });
        return button.render();
      );
  });

  # custom picture uploader
  $.extend($.summernote.plugins, {
    'picture2': (context)->
      self = this;
      ui = $.summernote.ui;
      context.memo('button.picture2', ()->
        button = ui.button({
          contents: 'Picture',
          tooltip: 'Picture',
          className: 'btn-picture',
          click: ()->
            content = """
              <form class='remote' data-type="json" action="/dashboard/contents/upload_image" data-remote="true" method="post">
                <label>Select from files</label>
                <div class="input-group"> 
                 <input class="note-image-input form-control required" name="images[]" accept="image/*" multiple="multiple" type="file">
                 <span class="input-group-btn"><button class="btn btn-default" type="submit" data-disable-with="<i class='fa fa-spinner fa-spin'></i> Processing...">Submit</button> </span> 
                </div>
              </form>
              <form class="form-group note-group-image-url">
                <label>Image URL</label>
                <div class="input-group">
                  <input class="note-image-url form-control required url" type="text">
                  <span class="input-group-btn"><button class="btn btn-default" type="submit">Submit</button> </span>
                </div>
              </form>
            """
            modal = modal_tpl({id: 'editor_modal_image', title: 'Insert Image', content:content})
            modal.modal()
            
            # updaload url
            modal.find('form.remote').on('ajax:success', (req, files)->
              for file in files
                if file.errors
                  new ToastNotificator(file.errors, {}, 'error')
                else
                  context.invoke('editor.insertImage', file.url)
              $('#editor_modal_image').modal('hide')
            ).on('ajax:complete', ->
              $(this).find('input:file').val('')
            ).validate()
            
            # static url
            modal.find('.note-group-image-url').submit(->
              context.invoke('editor.insertImage', $(this).find('input:text').val())
              $('#editor_modal_image').modal('hide')
              return false
            ).validate()
        })
        return button.render();
      )
  });
  
  
  $.extend($.summernote.plugins, {
    'stickerpipe': (context)->
      self = this;
      ui = $.summernote.ui;
      context.memo('button.stickerpipe', ()->
        button = ui.button({
          contents: 'Emoji',
          tooltip: 'Emoji',
          className: 'btn-emoji',
          click: ()->
            context.invoke('editor.saveRange')
        })
        return button.render();
      )

      this.events = {
        'summernote.init': (we, e)->
          window['editor-emoji-btns'] = (window['editor-emoji-btns'] || 0) + 1
          id = 'editor-emoji-btn-' + window['editor-emoji-btns']
          btn = e.toolbar.find('.btn-emoji').attr('id', id)
          config = {}
          config[k] = v for k,v of window.stickerPipeConfig
          config.elId = id
          stickerpipe = new Stickers(config)
          stickerpipe.render ->
            stickerpipe.onClickSticker (text) ->
              context.invoke('editor.restoreRange')
              stickerpipe.parseStickerFromText text, (sticker, isAsync) ->
                context.invoke('editor.insertNode', $(sticker.html)[0])
      }
      return
  });
  
  # remote file uploader for summernote
  $.fn.summerUploader = (files)->
    editor = $(this)
    data = new FormData();
    for file in files
      data.append("images[]", file);
    btn = editor.next().find('.btn-picture')
    $.rails.disableFormElement(btn)
    $.ajax({
      url: editor.attr('data-upload-url') || '/dashboard/contents/upload_image.json',
      data:data,
      type:'POST',
      contentType: false,
      processData: false,
      success: (files)->
        for file in files
          if file.errors
            new ToastNotificator(file.errors, {}, 'error')
          else
            editor.summernote('insertImage', file.url);
      ,
      complete: ->
        $.rails.enableFormElement(btn)
    });
  