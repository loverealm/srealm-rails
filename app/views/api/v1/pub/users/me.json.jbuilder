json.partial! 'api/v1/pub/users/simple_user', user: current_user
json.extract! current_user, :email, :roles, :last_name, :nick, :sex, :country, :location, :first_name, :is_newbie, :phone_number
json.credits current_user.credits.to_f
json.prevent_posting_until current_user.prevent_posting_until.try(:to_i)
json.prevent_commenting_until current_user.prevent_commenting_until.try(:to_i)
json.birthdate current_user.birthdate_to_i
json.biography current_user.the_biography
json.cover_photo_url current_user.cover.url
json.created_at current_user.created_at.to_i
json.updated_at current_user.updated_at.to_i
json.bot_information_filled true
json.bot_id User.bot_id
json.is_mentor current_user.mentor?

json.partial! 'api/v1/pub/users/settings', user: current_user