json.partial! 'api/v1/pub/users/simple_user', user: @user
json.extract! @user, :email, :roles, :last_name, :nick, :sex, :country, :location, :first_name, :is_newbie, :phone_number
json.birthdate @user.birthdate_to_i
json.biography @user.the_biography
json.cover_photo_url @user.cover.url
json.created_at @user.created_at.to_i
json.updated_at @user.updated_at.to_i
json.bot_information_filled true
json.bot_id User.bot_id
json.is_mentor @user.mentor?

json.partial! 'api/v1/pub/users/settings', user: @user