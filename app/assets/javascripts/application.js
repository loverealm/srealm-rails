// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= stub libraries/twitterfontana/manifest.js
//= stub admin_manifest.js

//= require jquery
//= require bootstrap-sprockets
//= require jquery_ujs
//= require jquery-ui.min
//= require jquery.tagsinput
//= require js.cookie
//= require jquery.remotipart
//= require jquery.inview
//= require jquery.timeago
//= require libraries/toastr
//= require typeahead.bundle
//= require admin/dashboard
//= require stickerpipe
// user mentions
//= require libraries/jquery.mentions
//= require libraries/jquery-confirm/jquery-confirm.min
//= require fixedsticky
//= require libraries/select2.min
//= require libraries/html.sortable.min
//= require libraries/isotope
//= require libraries/pwstrength-bootstrap.min
//= require libraries/bootstrap-filestyle
//= require libraries/bxslider/jquery.bxslider
//= require moment
//= require bootstrap-datetimepicker
//= require stickers
//= require_tree .

jQuery(document).ready(function($) {
    // dismiss existent alerts after 5 seconds
    setTimeout(function(){ $('div.alert').not('.skip_dismiss').fadeOut(500, function(){ $(this).remove(); }); }, 5000);

    // $('.remove').on('click', function() {
    //     $(this).remove();
    // });


    // Date time
    $.fn.datetimepicker.defaults['format'] = 'YYYY-MM-DD HH:mm A';
    $('#datepicker, div.input-group.date').datetimepicker({format: 'YYYY-MM-DD'});
    $('div.input-group.time').datetimepicker();
    
    // timepicker fix
    $('body').on('focus', 'div.input-group.date input:text, div.input-group.time input:text', function(){ $(this).next('.input-group-addon').click(); });
    
    
    //make ask button disabled
    $(document).on('click', "#ask", function(){
        $(this).attr("disabled", "disabled");
    });

    // remove current element after complete fadeOut
    $.fn.removeAnimated = function(speed){
        $(this).fadeOut(speed, function(){ $(this).remove(); });
        return this;
    };

    // fix for multiple modals
    $('body').on('hidden.bs.modal', '.modal', function(){
        var activeModal = $('.modal.in:last', 'body').data('bs.modal');
        if (activeModal) {
            activeModal.$body.addClass('modal-open');
            activeModal.enforceFocus();
            activeModal.handleUpdate();
        }
    });
    
    // jquery validation customizations
    $.validator.setDefaults({
        ignore: 'input[type=hidden]',
        errorPlacement: function(error, element) {
            if(element.parent().is('.input-group')) {
                error.insertAfter(element.parent());
            } else {
                error.insertAfter(element);
            }
        }
    });
    $.validator.prototype.checkForm = function() {
        this.prepareForm();
        for ( var i = 0, elements = (this.currentElements = this.elements()); elements[i]; i++ ) {
            if (this.findByName( elements[i].name ).length != undefined && this.findByName( elements[i].name ).length > 1) {
                for (var cnt = 0; cnt < this.findByName( elements[i].name ).length; cnt++) {
                    this.check( this.findByName( elements[i].name )[cnt] );
                }
            } else {
                this.check( elements[i] );
            }
        }
        return this.valid();
    };
    
    // default settings for select2
    $.fn.select2.defaults.set("width", "100%");
});

window['init_press_page'] = function(panel){
    var $ul = $('.left-section ul');
    $(window).scroll(function() {
        var offset = $(window).scrollTop();

        if(offset > 678) {
            $ul.addClass('fixed')
        } else {
            $ul.removeClass('fixed');
        }
    });
};

window['swap_json_key_value'] = function(json){
    var ret = {};
    for(var key in json){
        ret[json[key]] = key;
    }
    return ret;
};