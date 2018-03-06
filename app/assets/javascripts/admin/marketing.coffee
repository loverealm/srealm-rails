window['marketing_index_page'] = (panel)->
  panel = $(panel)
  toolbar = [
    ['style', ['bold', 'italic', 'underline', 'clear']],
    ['font', ['strikethrough', 'superscript', 'subscript']],
    ['fontsize', ['fontsize']],
    ['color', ['color']],
    ['para', ['ul', 'ol', 'paragraph']],
    ['height', ['height']],
    ['link', ['linkDialogShow', 'unlink']]
  ]
  panel.find('#send_email_form textarea').summernote({height: 300, toolbar: toolbar})
  panel.find('#send_email_form').validate({ignore: ''})
  
  panel.find('#send_message_form').validate()