require 'rails_helper'
RSpec.describe Api::V1::Pub::DashboardController, type: :controller do
  describe 'GET #switch_background_mode' do
    it 'Switch to background' do
      d = User.find(18).mobile_tokens.first
      get :switch_background_mode, mode: 'background', device_token: d.device_token
      response.should be_success
    end
  end
end