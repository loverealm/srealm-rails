json.array! @appointments do |appointment|
  json.partial! 'simple', appointment: appointment
end