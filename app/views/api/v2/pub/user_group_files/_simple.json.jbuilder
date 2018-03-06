json.extract! file, :id, :file_content_type
json.created_at file.created_at.to_i
json.url file.image.url