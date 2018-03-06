class @ProfileManager
  edit_information: (form)=>
    $.fn.repeat_until_run('google.maps.places', -> new google.maps.places.Autocomplete(form.find('.city_field')[0]))
    form.find('.profession_select').userAutoCompleter()
    form.validate()

  my_preferences_edit: (form)=>
    form.find('select[multiple]').each(->  $(this).children().first().prop('selected', true) if $(this).val() == [] || !$(this).val() )
    form.find('select').select2({width: '100%'})
    form.validate()
    
# initialize actions on use profile page
window['user_profile_page'] = ->
  container = $('#main_container')
  sidebar = container.find('#sidebar')
  iso = sidebar.find('.gallery_images').imagesLoaded(->
    iso.isotope({itemSelector: '.grid-item', layoutMode: 'masonry', columnWidth: 165, gutterWidth: 5})
  )