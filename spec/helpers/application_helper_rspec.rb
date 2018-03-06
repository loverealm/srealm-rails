require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  let(:user) { FactoryGirl.create(:user) }
  it 'Check datetime conversor' do
    allow(helper).to receive(:current_user).and_return(user)
    expect(helper.time_convert_to_visitor_timezone('2017-10-19 10:20 PM').class).to be(ActiveSupport::TimeWithZone)
    expect(helper.time_convert_to_visitor_timezone('2017-10-19 10:20').class).to be(ActiveSupport::TimeWithZone)
    expect(helper.time_convert_to_visitor_timezone('1507578633269').class).to be Time
    expect(helper.time_convert_to_visitor_timezone(1507578633269).class).to be Time
  end

  describe 'Payments' do
    it 'User buy credits' do
      # TODO test payments for paypal, stripe, rave
    end
  end
end