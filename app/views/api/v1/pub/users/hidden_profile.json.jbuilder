json.extract! @user, :sex
json.full_name @user.full_name(false, Time.current)
json.avatar_url @user.avatar_url(Time.current)
json.is_blocked current_user.blocked_to?(@user)
json.blocked_me @user.blocked_to?(current_user)
json.biography @user.the_biography(100, Time.current)