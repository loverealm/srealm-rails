require 'rails_helper'

RSpec.describe UserGroup, type: :model do
  it 'revenue data' do
    group = create(:user_group)
    expect(group.revenue_data('this_week').class).to eql(Hash)
    expect(group.revenue_data('this_month').class).to eql(Hash)
    expect(group.revenue_data('today').class).to eql(Hash)
    expect(group.revenue_data('this_year').class).to eql(Hash)
    expect{group.revenue_data('this_yearr')}.to raise_error('Invalid Period')
  end
  
  it 'default user group' do
    group = create(:user_group, privacy_level: 'closed', kind: 'church')
    group2 = create(:user_group, privacy_level: 'closed', kind: 'church')
    user1 = create(:user)
    user2 = create(:user)
    user3 = create(:user)
    group.add_members([user1.id])
    group2.add_members([user2.id])
    expect(user1.primary_church.id).to eql(group.id)
    expect(user2.set_default_church(group.id)).to eql(false)
    expect(user2.set_default_church(group2.id)).to eql(true)
    expect(user2.primary_church.id).to eql(group2.id)
    expect(user3.primary_church).to eql(nil)
    
    group.leave_group(user1.id)
    expect(User.find(user1.id).primary_church).to eql(nil)
  end
  
  it 'broadcast all_unread_broadcast_messages report' do
    group = create(:user_group, privacy_level: 'closed', kind: 'church')
    group.add_members([create(:user).id, create(:user).id, create(:user).id, create(:user).id])
    group.broadcast_messages.normal.create!(message: 'sample', user: group.user)
    expect(group.all_unread_broadcast_messages.class).to eql(Message::ActiveRecord_AssociationRelation)
    expect(group.all_unread_broadcast_messages('this_month').class).to eql(Hash)
    expect(group.all_unread_broadcast_messages('last_month').class).to eql(Hash)
    expect(group.all_unread_broadcast_messages('last_6_months').class).to eql(Hash)
    expect(group.all_unread_broadcast_messages('this_year').class).to eql(Hash)
  end

  it 'broadcast all_read_broadcast_messages report' do
    group = create(:user_group, privacy_level: 'closed', kind: 'church')
    group.add_members([create(:user).id, create(:user).id, create(:user).id, create(:user).id])
    group.broadcast_messages.normal.create!(message: 'sample', user: group.user)
    expect(group.all_read_broadcast_messages.class).to eql(Message::ActiveRecord_AssociationRelation)
    expect(group.all_read_broadcast_messages('this_month').class).to eql(Hash)
    expect(group.all_read_broadcast_messages('last_month').class).to eql(Hash)
    expect(group.all_read_broadcast_messages('last_6_months').class).to eql(Hash)
    expect(group.all_read_broadcast_messages('this_year').class).to eql(Hash)
  end
  
  it 'broadcast count_broadcast_sms report' do
    group = create(:user_group, privacy_level: 'closed', kind: 'church')
    group.add_members([create(:user).id, create(:user).id, create(:user).id, create(:user).id])
    group.broadcast_messages.normal.create!(message: 'sample', user: group.user) 
    expect(group.count_broadcast_sms('this_month').class).to eql(Hash)
    expect(group.count_broadcast_sms('last_month').class).to eql(Hash)
    expect(group.count_broadcast_sms('last_6_months').class).to eql(Hash)
    expect(group.count_broadcast_sms('this_year').class).to eql(Hash)
  end
  
  it 'verified status' do
    group = create(:user_group, privacy_level: 'closed', kind: 'church')
    expect(group.is_verified?).to eql(false)
    payment = group.payments.new(amount: 2)
    expect(payment.valid?).to eql(false) 
    
    group.send_verification_email
    group.mark_verified!
    expect(group.is_verified).to eql(true)
  end
  
end
