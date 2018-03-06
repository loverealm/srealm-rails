require 'rails_helper'

RSpec.describe Admin::VerifiedAdsController, type: :controller do
  login_admin

  describe 'GET #index' do
    # render_views
    it 'list of non verified ads' do
      group = create(:user_group)
      promo = create(:promotion_group, promotable: group)
      get :index
      expect(response.status).to eq(200)
    end

    it 'approve non verified group' do
      group = create(:user_group)
      promo = create(:promotion_group, promotable: group)
      post :approve, id: promo.id
      expect(response.status).to eq(200)
      promo = Promotion.find(promo.id)
      expect(promo.is_approved?).to eq(true)
    end
  end
end