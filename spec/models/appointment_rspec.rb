require 'spec_helper'
describe 'Appointment', type: :model do
  it 'Valid walk in' do
    appo = FactoryGirl.create(:appointment)
    puts "!!!!!!!!!!!!: #{appo.inspect}"
    expect(appo.errors.count).to eql(2) 
  end
end
