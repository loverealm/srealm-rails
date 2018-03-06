json.array! @items do |item|
  json.partial! 'single', convert: item
end