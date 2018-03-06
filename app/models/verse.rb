class Verse < ActiveRecord::Base
  scope :english, ->{ where(translation_id: 3) }
end