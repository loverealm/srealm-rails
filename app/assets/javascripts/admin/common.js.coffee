window['daily_devotion_form'] = (panel)->
  panel.find('textarea.editor').feedEditor({height: '240px'})
  panel.find('select.tags').tags_autocomplete()