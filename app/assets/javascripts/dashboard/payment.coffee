class @Payment
  form: (panel)=>
    @panel = panel
    @form = @panel.closest('form').on('ajax:complete', @reset_form)
    # @paypal_payment(panel)
    @card_payment(panel)
    @recurring_payment(panel)
    # $.fn.repeat_until_run('StripeCheckout', @stripe_payment)
    $.fn.repeat_until_run('getpaidSetup', @rave_payment)
    
  # permit to pay with exist cards
  card_payment: (panel)=>
    panel.on('change', 'input[name="pay_with_saved_card"]', ->
      if $(this).val()
        panel.find('.token_payment_panel').show().find('select').addClass('required')
        panel.find('.card_payment_panel').hide()
      else
        panel.find('.token_payment_panel').hide().find('select').removeClass('required')
        panel.find('.card_payment_panel').show()
    )
    
    panel.find('button.btn-token').click(->
      $(this).loadingButton()
      panel.closest('form').submit()
    )

  # controls the actions for recurring payments
  recurring_payment: (panel)=>
    custom_tpl = panel.find('.custom_recurring_tpl').remove()
    panel.on('change', 'select.payment_recurring', ->
      p = $(this).closest('.col_sel')
      if $(this).val() == 'custom'
        p.removeClass('col-md-12').addClass('col-md-6').next().html(custom_tpl.clone())
      else
        p.addClass('col-md-12').removeClass('col-md-6').next().html('')
    ).find('select.payment_recurring').trigger('change')
    
  # rave payment
  rave_payment: =>
    form = @form
    btn = form.find('.rave_btn').click(=>
      return false unless form.valid()
      if form.find('input.card_token').val()
        form.find('input.payment_method').val('rave')
        btn.loadingButton()
        form.submit()
        return true
      a = getpaidSetup(
        {
          PBFPubKey: @panel.attr('data-rave-key')
          customer_email: @panel.attr('data-email')
          customer_firstname: @panel.attr('data-name')
          customer_phone: @panel.attr('data-phone')
          custom_logo: @panel.attr('data-logo')
          custom_title: 'LoveRealm'
          amount: form.find('input[name="amount"]').val()
          country: 'GH'
          currency: @panel.attr('data-currency')
          txref: "rave-#{new Date()}"
          payment_method: 'both'
          onclose: ->
          callback: (response) ->
            if response.tx.chargeResponseCode == '00' or response.tx.chargeResponseCode == '0'
              form.find('input.card_token').val(response.tx.flwRef)
              setTimeout(->
                $('#flwpugpaidid').remove()
                btn.click()
              , 1500)
            return
        }
      )
    )

  # stripe payment
  stripe_payment: =>
    form = @form
    btn = form.find('.stripe_btn')
    handler = StripeCheckout.configure(
      key: @panel.data('stripe-key')
      image: @panel.attr('data-logo')
      locale: 'auto'
      token: (token) ->
        console.log("tokeen", token)
        form.find('input.card_token').val(token.id)
        btn.click()
        return
    )
      
    # btn to pay
    btn.click =>
      return false unless form.valid()
      if form.find('input.card_token').val()
        btn.loadingButton()
        form.find('input.payment_method').val('stripe')
        form.submit()
        return true

      handler.open
        name: 'LoveRealm'
        description: ''
        zipCode: true
        email: @panel.attr('data-email')
        amount: parseFloat(form.find('input[name="amount"]').val()) * 100
      
  paypal_payment: (panel)=>
    btn = @form.find('.paypal_btn')
    btn.click(=>
      return false unless @form.valid()
      @form.find('input.payment_method').val('paypal')
      @form.data('remote', false).submit()
      btn.loadingButton()
    )

  reset_form: =>
    @panel.find('.payment-btns button, .token_payment_panel .loadingButton').loadingButton(true)
    @panel.find('input.card_token, input.payment_method').val('')
    