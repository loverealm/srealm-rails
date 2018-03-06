json.extract! appointment, :id, :session_id, :finished, :kind, :latitude, :longitude, :location, :status
json.schedule_for appointment.schedule_for.try(:to_i)
json.re_schedule_for appointment.re_schedule_for.try(:to_i)
json.is_finished appointment.finished?
json.mentor do
  json.partial! 'api/v1/pub/users/simple_user', user: appointment.mentor
end
json.mentee do
  json.partial! 'api/v1/pub/users/simple_user', user: appointment.mentee
end