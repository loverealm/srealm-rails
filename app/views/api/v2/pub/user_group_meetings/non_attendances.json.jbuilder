json.array!@non_attendances do |non_attendance|
  json.extract! non_attendance, :id, :reason, :user_id
  json.name non_attendance.user.full_name(false, non_attendance.created_at)
end