class AppointmentDecorator < ApplicationDecorator
  delegate_all
  def the_row_item(attrs = {}, &block)
    attrs = {class: '', avatar_size: 30}.merge(attrs)
    mentee_mode = object.mentee_id == h.current_user.id
    _user = mentee_mode ? object.mentor : object.mentee
    links, media_right = [[], '']
    time = object.the_date
    
    if object.pending?
      if mentee_mode
        links << h.link_to('Cancel', h.dashboard_appointment_path(id: object), title: 'Cancel Appointment', method: :delete, 'data-confirm'=>'Are you sure you want to cancel this appointment?', class: 'btn btn-primary btn-bordered btn-xs ujs_success_remove', remote: true, 'data-closest-remove'=>'.media', 'data-disable-with' => h.button_spinner) if h.can?(:cancel, object)
        links << h.link_to('Edit', h.edit_dashboard_appointment_path(id: object), title: 'Edit Appointment', class: 'btn btn-warning btn-bordered btn-xs ujs_link_modal', remote: true, 'data-disable-with' => h.button_spinner) if h.can?(:edit, object)
        links << h.link_to('Accept Re-sched.', h.accept_dashboard_appointment_path(id: object), class: 'btn btn-success btn-bordered btn-xs ujs_success_hide ujs_content_to', remote: true, 'data-prepend-to' => '#leftbar .mentor_appointments .upcoming-list', 'data-closest-hide'=>'.media', 'data-disable-with' => h.button_spinner) if h.can?(:accept_reschedule, object)
      else
        unless object.is_reschedule_request?
          links << h.link_to('Accept', h.accept_dashboard_appointment_path(id: object), class: 'btn btn-success btn-bordered btn-xs ujs_success_hide ujs_content_to', remote: true, 'data-prepend-to' => '#leftbar .mentor_appointments .upcoming-list', 'data-closest-hide'=>'.media', 'data-disable-with' => h.button_spinner) if h.can?(:accept, object)
          links << h.link_to('Re-sched.', h.re_schedule_dashboard_appointment_path(id: object), title: 'Re Schedule', class: 'btn btn-warning btn-bordered btn-xs ujs_link_modal', remote: true, 'data-modal-title'=>'Appointment Re Schedule For', 'data-disable-with' => h.button_spinner) if h.can?(:reschedule, object)
          links << h.link_to('Reject', h.reject_dashboard_appointment_path(id: object), title: 'Not Interested', class: 'btn btn-danger btn-xs ujs_success_remove', remote: true, 'data-closest-remove'=>'.media', 'data-confirm' => 'Are you sure?', 'data-disable-with' => h.button_spinner) if h.can?(:reject, object)
        else
          links << '<span class="label label-default">Re-scheduled</span>' unless object.is_past?
        end
      end
    else
      if object.is_video?
        links << h.link_to('Call', h.start_call_dashboard_appointment_path(id: object), class: 'btn btn-success btn-bordered btn-xs') if h.can?(:start_call, object)
      else
        links << '<span class="label label-success">Counseling time</span>' if object.is_meeting_time?
      end
    end
    links << h.link_to('Show', h.dashboard_appointment_path(id: object, modal: true), class: 'btn btn-default btn-bordered btn-xs ujs_link_modal', remote: true, 'data-modal-title' => "Appointment - #{h.localize(time, format: :short)}", 'data-disable-with' => h.button_spinner('...'))
    
    "<div class='media #{attrs[:class]} appointment_item' data-id='#{object.id}'>
      <div class='media-left'>
        #{h.user_avatar_widget(_user, attrs[:avatar_size], object.created_at)}
      </div>
      <div class='media-body'>
        <div class='small margin_bottom10'>
          <b>#{_user.full_name(false, object.created_at)}</b> - <small>#{time ? h.localize(time, format: :short) : ''}</small><br>
          <span class='text-gray small'>#{object.the_kind}</span>
        </div>
        #{block ? h.capture(&block) : ''}
        <div class='links'> #{links.join(' ')} </div>
      </div>
      #{media_right}
    </div>".html_safe
  end
end
