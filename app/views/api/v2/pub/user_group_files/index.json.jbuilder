json.array! @files do |file|
  json.partial! 'api/v2/pub/user_group_files/simple', file: file
end