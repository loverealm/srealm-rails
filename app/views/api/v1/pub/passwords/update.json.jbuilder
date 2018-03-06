json.extract! @user, :id, :email, :verified 
json.full_name @user.full_name
json.avatar_url @user.avatar_url

