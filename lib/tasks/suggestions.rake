namespace :suggestions do
  desc "Generate friend suggestions every day at 5am: 5 0 * * *"
  task generate: :environment do
    friends_suggestions = BotSuggestionService::DailySuggestion.new('friends')
    Delayed::Job.enqueue(friends_suggestions)

    partners_suggestions = BotSuggestionService::DailySuggestion.new('dating')
    Delayed::Job.enqueue(partners_suggestions)
  end
end