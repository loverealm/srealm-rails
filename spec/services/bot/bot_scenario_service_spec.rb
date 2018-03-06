require 'rails_helper'
require 'support/bot_questions_init'

RSpec.describe BotScenarioService do
  let(:user) { FactoryGirl.create(:user) }
  let!(:bot) { FactoryGirl.create(:bot) }

  before do
    init_bot_questions
  end

  def init_scenario_service
    dating_scenario = BotScenario.find_by(scenario_type: 'dating')
    conversation = FactoryGirl.create(:conversation_with_bot, new_members: [bot.id, user.id], bot_scenario_id: dating_scenario.id)
    bot_service = BotScenarioService.new(user: user,
                                         conversation: conversation,
                                         bot: bot,
                                         message: FactoryGirl.create(:message, sender_id: user.id))
    bot_service.questions = BotQuestion.where(bot_scenario_id: dating_scenario.id)
    bot_service
  end

  describe 'private methods' do
    describe '#init_scenario_conversation' do
      it 'resets current user meta info and asks the first question' do
        user.update(suggestion_type: 'friends')
        bot_service = init_scenario_service
        bot_service.send(:init_scenario_conversation)
        expect(user.meta_info).to eq Hash.new
        expect(bot.sent_messages.last.body).to eq bot_service.send(:process_question_text,
                                                                    BotQuestion.where(bot_scenario: bot_service.conversation.bot_scenario).first.text)
      end
    end

    describe '#answer_is_positive?' do
      describe 'returns true' do
        it 'returns true when there is a correct answer about nationality' do
          user_answer = 'nationality is American'
          bot_service = BotScenarioService.new
          expect(bot_service.send(:answer_is_positive?, user_answer)).to eq true
        end

        it 'returns true when user answered YES' do
          user_answer = 'yes'
          bot_service = BotScenarioService.new
          expect(bot_service.send(:answer_is_positive?, user_answer)).to eq true
        end
      end

      describe 'returns false' do
        it 'returns false when user answered NO' do
          user_answer = 'no'
          bot_service = BotScenarioService.new
          expect(bot_service.send(:answer_is_positive?, user_answer)).to eq false
        end

        it 'returns false when user answered something else' do
          user_answer = 'ABRA-CADABRA'
          bot_service = BotScenarioService.new
          expect(bot_service.send(:answer_is_positive?, user_answer)).to eq false
        end
      end
    end
  end

end
