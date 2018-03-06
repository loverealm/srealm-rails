$ ->
  jQuery.validator.addMethod("required_if", (value, element, other_element)->
    ele = $(other_element)
    _val = ele.val()
    _val = ele.is(':checked') if ele.is('input:checkbox') || ele.is('input:radio')
    return true if _val
    return true if value
    return false
  , "This field is required if the previous field is empty.");

  jQuery.validator.addMethod("greater_than", (value, element, other_element)->
    ele = $(other_element)
    parseInt(ele.val()) <= parseInt(value)
  , "This field must be great than previous field value.");
  
  # jquery validation customizations
  $.validator.setDefaults({
    ignore: 'input[type=hidden]',
    errorPlacement: (error, element)->
      if(element.parent().is('.input-group'))
        error.insertAfter(element.parent());
      else
        error.insertAfter(element);
  })
  
  $.validator.prototype.checkForm = ()->
    this.prepareForm()
    elements = (this.currentElements = this.elements())
    for element in elements
      if (this.findByName(element.name).length != undefined && this.findByName(element.name).length > 1)
        for element2 in this.findByName(element.name )
          this.check(element2)
      else
        this.check(element);
    return this.valid();