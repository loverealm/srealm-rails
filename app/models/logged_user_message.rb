class LoggedUserMessage < ActiveRecord::Base
  before_save :downcase_and_strip_text
  has_many :bot_custom_answers, dependent: :destroy
  validates :text, uniqueness: true

  private

  def downcase_and_strip_text
    self.text = text.downcase.strip if text
  end
end
