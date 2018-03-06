require 'rake'
Rails.application.load_tasks

def init_bot_questions
  Rake::Task['bot:recreate_messages'].invoke
end
