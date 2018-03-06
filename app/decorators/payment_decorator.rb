class PaymentDecorator < ApplicationDecorator
  delegate_all
  
  # return recurring label
  def the_recurring_label
    if object.is_active_recurring
      h.content_tag :span, 'Recurring Payment', class: 'label label-success'
    elsif object.recurring_period
      h.content_tag :span, 'Recurring Stopped', class: 'label label-warning'
    elsif object.parent_id
      h.content_tag :span, 'Recurring Transaction', class: 'label label-default'
    end
  end
  
  def the_dropdown_options
    res = [h.content_tag(:li, h.link_to('<i class="fa fa-eye"></i> View details'.html_safe, h.url_for(action: :show_payment, id: object.id), class: 'ujs_link_modal', 'data-disable-with' => h.button_spinner, remote:true, 'data-modal-title' => 'Payment Details'))]
    res << h.content_tag(:li, h.link_to('<i class="fa fa-flash"></i> Stop Recurring Payment'.html_safe, h.url_for(action: :stop_recurring, id: object), method: :post, class: 'ujs_success_replace', 'data-closest-replace' => 'tr', 'data-disable-with' => h.button_spinner, 'data-confirm' => 'Are you sure you want to stop this recurring payment?', remote: true)) if object.is_active_recurring
    h.dropdown_builder(button_class: 'btn-xs') do
      res.join('').html_safe
    end
  end
end