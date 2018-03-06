require 'rails_helper'

RSpec.describe InfobipService do
  it 'Calculate message cost' do
    WebMock.allow_net_connect!
    cost = InfobipService.calculate_cost(['59179716902', '+59179716902', '591 79716902', '59170752773'], 'Hello world')
    WebMock.disable_net_connect!
    expect(cost).to eq(2)
  end
end