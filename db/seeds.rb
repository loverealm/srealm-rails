# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

%w(#Jealousy #Love #Relationships #Prayer #Jesus).each do |hash_tag|
  h = HashTag.new
  h.name = hash_tag
  p "HashTag #{hash_tag} has been created" if h.save
end

# Bot initialization
run_welcome_message = false

# Bot scenarios initialization
%w(dating friends help matching).each do |type|
  BotScenario.create(scenario_type: type, description: type + ' bot') unless BotScenario.exists?(scenario_type: type)
end
p 'Bot scenarios created'

# Bot questions initialization
# NOTE: Capitalized words will be replaced with the user info

dating_questions = [
  {
    text: 'Do Physical features matter to you? 1. Yes 2. No',
    field_for_update: nil,
    position: 1,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'This would require that you provide me with a little more info about yourself. What’s your height in ft.?',
    when_to_run: 'previous_is_true',
    field_for_update: 'height',
    position: 2,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  },
  {
    text: 'How would you describe your body type?(1. average, 2. slim, 3. plus size, 4. curvy, 5. athletic)',
    field_for_update: 'body_type',
    position: 3,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'average', '2': 'slim', '3': 'plus size', '4': 'curvy', '5': 'athletic'}
  },
  {
    text: 'How tall should he/she be? In ft.',
    field_for_update: 'preferred_height',
    position: 4,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  },
  {
    text: 'Do you have a preferred body type? (1. average, 2. slim, 3. plus size, 4. curvy, 5. athletic)',
    field_for_update: 'preferred_body_type',
    position: 5,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'average', '2': 'slim', '3': 'plus size', '4': 'curvy', '5': 'athletic'}
  },
  {
    text: 'What is your ethnicity? (1.Black, 2.caucasian, 3. asian, 4. mixed, 5. European, 6. Middle Eastern/Arabic, 7. Hispanic, 8. Pacific Islander)',
    field_for_update: 'ethnicity',
    position: 6,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'black', '2': 'caucasian', '3': 'asian', '4': 'mixed', '5': 'european', '6': 'middle eastern/arabic', '7': 'hispanic', '8': 'pacific islander'}
  },
  {
    text: 'What is the highest level of your educational attainment? (1. High school, 2. College, 3. University, 4. Post-Graduate)',
    field_for_update: 'education',
    position: 7,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'high school', '2': 'college', '3': 'university', '4': 'post-graduate'}
  },
  {
    text: 'What is your profession?',
    field_for_update: 'profession',
    position: 8,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  },
  {
    text: 'What is your denomination?',
    field_for_update: 'denomination',
    position: 9,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  },
  {
    text: 'Should the search be limited to just your city, or not? 1. Yes 2. No',
    field_for_update: 'by_city',
    position: 10,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'In what city are you?',
    field_for_update: 'city',
    when_to_run: 'previous_is_true',
    position: 11,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  },
  {
    text: 'Does ethnicity matter to you? 1. Yes 2. No',
    field_for_update: 'ethnicity_matters',
    position: 12,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'What is your preferred ethnicity? (1. Black, 2. caucasian, 3. asian, 4. mixed, 5. European, 6. Middle Eastern/Arabic, 7. Hispanic, 8. Pacific Islander)',
    field_for_update: 'preferred_ethnicity',
    when_to_run: 'previous_is_true',
    position: 13,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'black', '2': 'caucasian', '3': 'asian', '4': 'mixed', '5': 'european', '6': 'middle eastern/arabic', '7': 'hispanic', '8': 'pacific islander'}

  },
  {
    text: 'Does age matter to you? 1. Yes 2. No',
    field_for_update: 'age_matters',
    position: 14,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'What is your preferred age? 1. Younger 2. Older 3. Age mate',
    field_for_update: 'preferred_age',
    when_to_run: 'previous_is_true',
    position: 15,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  },
  {
    text: 'Does educational attainment matter to you? 1. Yes 2. No',
    field_for_update: 'education_matters',
    position: 16,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'What is your preferred level of educational attainment (1. High school, 2. College, 3. University, 4. Post-Graduate)',
    field_for_update: 'preferred_education',
    when_to_run: 'previous_is_true',
    position: 17,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers:{'1': 'high school', '2': 'college', '3': 'university', '4': 'post-graduate'}
  },
  {
    text: 'Does denomination matter to you? 1. Yes 2. No',
    field_for_update: 'denomination_matters',
    position: 18,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'What is your preferred level of denomination?',
    field_for_update: 'preferred_denomination',
    when_to_run: 'previous_is_true',
    position: 19,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :dating).id
  }
]

friends_questions = [
  {
    text: "Two more questions and I'd be done. 1st Question: Does Age matter in the type of friendships you want to make on LoveRealm? 1. Yes 2. No",
    field_for_update: 'age_matters',
    position: 2,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :friends).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'What’s your prefered age for friends on LoveRealm?',
    field_for_update: 'preferred_age',
    when_to_run: 'previous_is_true',
    position: 3,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :friends).id
  },
  {
    text: 'Should the friends I suggest to you be limited to your locality? 1. Yes 2. No',
    field_for_update: 'by_city',
    position: 4,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :friends).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'In what city are you?',
    field_for_update: 'city',
    when_to_run: 'previous_is_true',
    position: 5,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :friends).id
  },
  {
    text: 'Should the friends I suggest to you be of the same denomination as yours? 1. Yes 2. No',
    field_for_update: 'denomination_matters',
    position: 6,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :friends).id,
    available_answers: {'1': 'yes', '2': 'no'}
  },
  {
    text: 'What denomination are you?',
    field_for_update: 'denomination',
    when_to_run: 'previous_is_true',
    position: 7,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :friends).id
  }
]

help_questions = [
  {
    text: "Hi NAME, I’m Dr. Love. I'm your first friend on LoveRealm :)",
    position: 1,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :help).id
  },
  {
    text: "I'd love to help you make more friends on LoveRealm if you dont mind.",
    position: 2,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :help).id
  },
  {
    text: "I'm presenting you with two options: 1. The option of Christian friends who will help you in your walk with God
2. Christian centered friendships that can lead to courtship",
    field_for_update: 'relationship_status',
    position: 3,
    bot_scenario_id: BotScenario.find_or_create_by(scenario_type: :help).id,
    when_to_run: 'no_relationship_status',
    available_answers: BotHelpService::RELATIONSHIP_STATUSES
  }
]

dating_questions.each do |q|
  BotQuestion.create(q) unless BotQuestion.where(bot_scenario_id: q[:bot_scenario_id]).exists?(text: q[:text])
end

friends_questions.each do |q|
  BotQuestion.create(q) unless BotQuestion.where(bot_scenario_id: q[:bot_scenario_id]).exists?(text: q[:text])
end

help_questions.each do |q|
  BotQuestion.create(q) unless BotQuestion.where(bot_scenario_id: q[:bot_scenario_id]).exists?(text: q[:text])
end

p "Bot questions created"

if Rails.env.development?
  # need to create an admin, otherwise RTE when registering a new user
  admin = User.create({
               first_name: 'admin',
               last_name: 'admin',
               email: 'admin@admin.com',
               password: '123123as',
               password_confirmation: '123123as',
               roles: [:admin]
  }).tap(&:confirm)
  

  # need to create a bot, otherwise RTE when connecting to faye
  bot = User.create!({
    first_name: 'bot',
    last_name: 'bot',
    email: 'bot@bot.bot',
    password: '123123as',
    password_confirmation: '123123as',
    roles: [:bot]
  }).tap(&:confirm)

  # need to create a content for initial greeting
  Content.create({content_type: 'daily_story',
                  title: 'Jesus is our savior',
                  description: 'Story description',
                  publishing_at: 2000.years.ago,
                  user: admin
  })
end