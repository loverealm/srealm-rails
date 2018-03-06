class @UserGroupsSuggested
  banner: (panel) =>
    panel.find('.list_items').bxSlider({
      minSlides: 3,
      maxSlides: 4,
      slideMargin: 2,
      slideWidth: 169,
      pager: false,
      infiniteLoop: false,
      hideControlOnEnd: true
    })