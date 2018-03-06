var Form = {

    validClass : 'valid',
    minLength : 1,

    validateLength : function(formEl){
        if(formEl.value.length < this.minLength ){
            if(formEl.classList.contains("valid-error")) {
                formEl.className.replace(/\bvalid-error\b/,'');
            }
            formEl.className += ' valid-error';
            $('.valid-error').parent().next('.error-message').show();
            $('.valid-error').parents().siblings('#imageError.error-message').show();
            $('.valid-error').next('.error-message').show()
            // formEl.nextSibling.neshow();
            return false;
        } else {
            if(formEl.className.indexOf(' '+Form.validClass) == -1)
            formEl.className += ' '+Form.validClass;
            return true;
        }
    },

    getSubmit : function(formID){
        var inputs = $('form').find('input');
        for(var i = 0; i < inputs.length; i++){
            if(inputs[i].type == 'submit'){
                return inputs[i];
            }
        }
        return false;
    }

};

$(document).ready(function() {
    $(".validating-form form, form.validate").each(function() {
      $( this ).validate();
    });
});
