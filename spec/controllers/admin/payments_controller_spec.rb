require 'rails_helper'

RSpec.describe Admin::PaymentsController, type: :controller do
  before(:all) do
    group = create(:user_group, privacy_level: 'closed', kind: 'church')
    group.mark_verified!
    payment = group.payments.new(amount: 2)
  end
  
  login_admin

  describe 'GET #index' do
    # TODO list of payments by filter
  end

  describe 'GET #mark as transferred' do
    # TODO list of payments by filter
  end

  describe 'GET #unmark as transferred' do
    # TODO list of payments by filter
  end
end