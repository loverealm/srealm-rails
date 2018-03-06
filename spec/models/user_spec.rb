require 'rails_helper'

describe User do
  describe '.create_from_omniauth' do
    it 'creates user if one does not exist' do
      auth_params = OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid:'123545',
        info: {
          name: 'Test',
          email: 'foo.bar@example.com'
        },
        credentials: {
          token: '1234123412341234'
        }
      })

      expect {
        User.create_from_omniauth(auth_params)
      }.to change{ User.count }.by(1)
    end

    it 'creates new identity if one does not exist' do
      user = FactoryGirl.create(:user)
      auth_params = OmniAuth::AuthHash.new({
        provider: 'facebook',
        uid:'123545',
        info: {
          name: user.full_name,
          email: user.email
        },
        credentials: {
          token: '1234123412341234'
        }
      })

      expect {
        User.create_from_omniauth(auth_params)
      }.to change{ Identity.count }.by(1)
    end

    it 'creates new identity if one does not exist' do
      user = FactoryGirl.create(:user)
      identity = FactoryGirl.create(:identity, user: user)

      auth_params = OmniAuth::AuthHash.new({
        provider: identity.provider,
        uid: identity.uid,
        info: {
          name: user.full_name,
          email: user.email
        },
        credentials: {
          token: '1234123412341234'
        }
      })

      expect {
        User.create_from_omniauth(auth_params)
      }.not_to change{ Identity.count }
    end
  end

  describe 'User restrictions' do
    it 'age restriction 13 years minimum' do
      user = build(:user, birthdate: (Date.today - 12.years))
      user.save
      expect(user.errors.count).to eql(1)

      user = build(:user, birthdate: (Date.today - 13.years))
      user.save
      expect(user.errors.count).to eql(0)
    end
  end

  describe 'User Anonymity' do
    it 'Creates no anonymity user' do
      user = FactoryGirl.create(:user)
      expect(user.is_anonymity?).to eql(false)
    end

    it 'Toggle anonymity status' do
      user = FactoryGirl.create(:user)
      user.toggle_anonymity!
      expect(user.is_anonymity?).to eql(true)
      expect(user.full_name(false, :now)).to eq('Anonymous')
      expect(user.avatar_url(:now)).to eq('/images/missing_avatar.png')
      expect(user.the_biography(100, :now)).to eq('')
    end
  end

  describe 'Last Visit Certain User Group' do
    it 'no new feeds exist' do
      user = create(:user)
      user_group = FactoryGirl.create(:user_group, user: user)
      expect(user.count_new_feeds_for_user_group(user_group.id)).to eql(0)
    end

    it 'new feeds exist' do
      user = create(:user)
      user2 = create(:user)
      user3 = create(:user)
      user_group = FactoryGirl.create(:user_group, user_id: user.id)
      user_group.add_members([user2.id, user3.id])
      st1 = create(:status, user_group_id: user_group.id, user: user)
      st2 = create(:status, user_group_id: user_group.id, user: user2)
      st3 = create(:status, user_group_id: user_group.id, user: user3)
      expect(user.count_new_feeds_for_user_group(user_group.id)).to eql(2)
    end
  end

  describe 'watchdog preventing' do
    it 'no prevent posting' do
      user = create(:user)
      expect(user.prevent_posting?).to eql(false)
    end
    it 'prevent posting' do
      user = create(:user, prevent_posting_until: 2.days.from_now)
      expect(user.prevent_posting?).to eql(true)
    end
    it 'no prevent posting past' do
      user = create(:user, prevent_posting_until: 2.days.ago)
      expect(user.prevent_posting?).to eql(false)
    end

    it 'no prevent commenting' do
      user = create(:user)
      expect(user.prevent_commenting?).to eql(false)
    end
    it 'prevent commenting' do
      user = create(:user, prevent_commenting_until: 2.days.from_now)
      expect(user.prevent_commenting?).to eql(true)
    end

    it 'no prevent commenting past' do
      user = create(:user, prevent_commenting_until: 2.days.ago)
      expect(user.prevent_commenting?).to eql(false)
    end
  end

  describe 'Volunteer' do
    it 'Invite volunteer' do
      user = create(:user)
      expect(user.can_show_invite_volunteer?).to eql(false)

      create(:status, user: user).update_column(:created_at, 0.days.ago)
      create(:status, user: user).update_column(:created_at, 1.days.ago)
      create(:status, user: user).update_column(:created_at, 2.days.ago)
      create(:status, user: user).update_column(:created_at, 3.days.ago)
      expect(user.can_show_invite_volunteer?).to eql(true)
    end
  end

  describe 'Counseling conversations' do
    it 'empty counseling conversations' do
      user1 = create(:user)
      user2 = create(:user)
      c = Conversation.get_single_conversation(user1.id, user2.id)
      expect(user1.counseling_conversations.count).to eql(0)
    end

    it 'many counseling conversations' do
      user1 = create(:user)
      user2 = create(:user)
      user3 = create(:user_other_mentor)
      user4 = create(:user_official_mentor)
      Conversation.get_single_conversation(user1.id, user3.id)
      expect(user1.counseling_conversations.count).to eql(1)
    end
  end
  
  describe 'User credits' do
    it 'Add credit' do
      user = create(:user)
      expect(user.credits).to eql(0)
      user.add_credits(10)
      expect(user.credits).to eql(10)
    end
  end
end
