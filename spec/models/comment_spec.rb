require 'rails_helper'

describe Comment do
  describe 'Verify bad words' do
    let(:user) { create(:user) }
    it 'comment with bad words' do
      bad_word = create(:word)
      status   = create(:status, description: "Sample content", user: user)
      comment = status.comments.create(body: "#{bad_word.name} test comment")
      expect(comment.body).to include('***')
    end
  end
end