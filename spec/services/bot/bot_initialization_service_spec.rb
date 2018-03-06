require 'rails_helper'
require 'support/bot_questions_init'

RSpec.describe BotInitializationService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:bot) { FactoryGirl.create(:bot) }

  before do
    init_bot_questions
  end

  describe '#call' do
    it 'creates conversation(bot help scenario) with bot if user has no one' do
      BotInitializationService.new(user: user).call
      expect(user.my_conversations.where(with_bot: true).count).to eq 1
      expect(user.my_conversations.where(with_bot: true).take.bot_scenario.scenario_type).to eq 'help'
    end

    it 'does not create conversation with bot is user has one already' do
      2.times do
        BotInitializationService.new(user: user).call
      end
      expect(user.my_conversations.where(with_bot: true).count).to eq 1
    end
  end
end
