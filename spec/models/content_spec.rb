require 'rails_helper'
describe Content do
  let(:user) { create(:user) }

  it 'does remove bad words' do
    bad_word = create :word
    status   = create(:status, description: "#{bad_word.name} content", user: user)
    expect(status.description).to include('***')
  end
end