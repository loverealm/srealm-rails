class DefaultFollowerService
  def initialize(user)
    @user = user
  end

  def assign
    if @user.following.blank?
      @user.suggested_users(1, 5).each do |user|
        @user.following << user
      end
    end

    mentions = Setting.get_setting_as_list(:default_following_accounts).map { |value| value[1..-1] }
    mentions.delete_if{|v| !v.present? }
    User.where(mention_key: mentions).each do |user|
      @user.following << user unless @user.following.include?(user)
    end

    if @user.phone_number.present?
      PhoneNumberInvitation.where(phone_number: @user.phone_number)
                           .find_each do |item|
        @user.following << item.user unless @user.following.include?(item.user)
      end
    end
  end
end