json.array! @promotions do |promotion|
  json.partial! 'api/v2/pub/promotions/simple', promotion: promotion
end