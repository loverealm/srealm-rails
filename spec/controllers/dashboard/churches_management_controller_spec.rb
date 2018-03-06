require 'rails_helper'

RSpec.describe Dashboard::ChurchesManagementController, type: :controller do
  login_user
  describe 'post #manual_payment' do
    it 'Manual payments needed for verification' do
      user_group = create(:user_group, user: subject.send(:current_user))
      post :manual_payment, user_group_id: user_group.id, payment: {amount: 10, goal: 'tithe', payment_at: (2.days.ago)}
      expect(response.body).to include(' payments yet.') 
    end

    it 'Manual payments success' do
      user_group = create(:user_group, user: subject.send(:current_user))
      user_group.mark_verified!
      post :manual_payment, user_group_id: user_group.id, payment: {amount: 10, goal: 'tithe', payment_at: (2.days.ago)}
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #manual_payment' do
    it 'Render modal' do
      user_group = create(:user_group, user: subject.send(:current_user))
      get :manual_payment, user_group_id: user_group.id
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #pending pledges' do
    it 'list/send reminder' do
      # TODO
    end
  end
end