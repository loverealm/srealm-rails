require 'rails_helper'

RSpec.describe Promotion, type: :model do
  it 'Approve Promotion' do
    group = create(:user_group)
    promo = create(:promotion_group, promotable: group)
    expect(promo.is_approved?).to eql(false)
    promo.mark_as_approved!
    expect(promo.is_approved?).to eql(true)
  end
end
