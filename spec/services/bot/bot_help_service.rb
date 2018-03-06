require 'rails_helper'
require 'support/bot_questions_init'

RSpec.describe BotHelpService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:bot) { FactoryGirl.create(:bot) }

  before do
    init_bot_questions
  end

  describe '#take_scenario_by_status' do
    it 'returns friends scenario for user that is below age of 18' do
      ###
    end
    
    it 'returns appropriate scenario for particular user status' do
      expect(BotHelpService.take_scenario_by_status(user)).to eq BotScenario.find_by(scenario_type: :help)
      user.update(relationship_status: :single_and_available)
      expect(BotHelpService.take_scenario_by_status(user)).to eq BotScenario.find_by(scenario_type: :dating)
      user.update(relationship_status: :single_and_unavailable)
      expect(BotHelpService.take_scenario_by_status(user)).to eq BotScenario.find_by(scenario_type: :friends)
      user.update(relationship_status: :no_info)
      expect(BotHelpService.take_scenario_by_status(user)).to eq BotScenario.find_by(scenario_type: :friends)
    end
  end

  describe '#call' do
    describe 'user has no relationship status' do
      it 'asks user about his relationship status' do
        conversation = Conversation.get_single_conversation(bot.id, user.id)
        conversation.update(with_bot: true, bot_scenario: BotHelpService.take_scenario_by_status(user))
        BotHelpService.new(user: user, bot: bot, conversation: conversation).call
        expect(conversation.messages.first.body).to eq BotQuestion.find_by(when_to_run: 'no_relationship_status').text
      end
    end
  end
end
