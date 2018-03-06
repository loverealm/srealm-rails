module Admin
  class HomeController < BaseController
    def index
      if current_user.admin?
        users_count = User.count
        @stats = {
          number_of_users: {
            total_count: users_count,
            male_share: percentage(User.where('sex = 0').count, users_count),
            female_share: percentage(User.where('sex = 1').count, users_count)
          },
          number_of_loves: ActsAsVotable::Vote.count,
          number_of_comments: Comment.count,
          number_of_shares: Share.count,
          monthly_active_users: monthly_active_users,
          joined_last_month: User.where('created_at > ?', 1.month.ago).count,
          net_promoter_score: percentage(
            PhoneNumberInvitation.uniq.count(:user_id), users_count)
        }
  
        @top_contents = {
          most_liked_contents: Content.order('cached_votes_score DESC').limit(5),
          most_shared_contents: Content.order('shares_count DESC').limit(5),
          most_commented_contents: Content.order('comments_count DESC').limit(5)
        }
        render 'index_admin'
      elsif current_user.is_watchdog?
        render 'index_watchdog'
      else
        render 'index'
      end
    end

    # return chart graphic for dashboard
    def chart
      data = case params[:kind]
               when 'number_of_users'
                 @title = 'Number of users '
                 User.group('DATE_TRUNC(\'month\', created_at)').count
               when 'number_of_loves'
                 @title = 'Number of Loves'
                 ActsAsVotable::Vote.group('DATE_TRUNC(\'month\', created_at)').count
               when 'number_of_comments'
                 @title = 'Number of comments'
                 Comment.unscoped.group('DATE_TRUNC(\'month\', created_at)').count
               when 'number_of_shares'
                 @title = 'Number of shares'
                 Share.group('DATE_TRUNC(\'month\', created_at)').count
               when 'monthly_active_users'
                 @title = 'Monthly active users'
                 votes = ActsAsVotable::Vote.group('DATE_TRUNC(\'month\', created_at)').count
                 comments = Comment.unscoped.group('DATE_TRUNC(\'month\', created_at)').count
                 shares = Share.group('DATE_TRUNC(\'month\', created_at)').count
                 votes
                     .merge(comments) { |k, a_value, b_value| a_value + b_value }
                     .merge(shares) { |k, a_value, b_value| a_value + b_value }
               when 'joined_last_month'
                 @title = 'Joined last month'
                 User.group('DATE_TRUNC(\'day\', created_at)').where(created_at: Date.today.beginning_of_month..Date.today.end_of_month).count
               else #net_promoter_score
                 @title = 'Net promoter score'
                 PhoneNumberInvitation.uniq.group('DATE_TRUNC(\'month\', created_at)').count(:user_id)
             end

      # data manipulation
      @data = []
      prev_key, year = nil, Time.current.year
      data.sort.each do |k ,v|
        k = k.to_date
        if params[:kind] == 'joined_last_month'
          (prev_key.next...k).each{|d| @data << [d.strftime('%d'), 0, "#{d.to_s(:long)} = 0"] } if prev_key.present?
          @data << [k.strftime('%d'), v, "#{k.to_s(:long)} = #{v}"]
        else
          k = k.beginning_of_month
          (prev_key.next..k.yesterday).select{|d| d.day == 1 }.each{|d| @data << [d.strftime(year == d.year ? '%m' : '%y/%-m'), 0, "#{d.strftime("%B, %Y")} = 0"] } if prev_key.present?
          @data << [k.strftime(year == k.year ? '%m' : '%y/%-m'), v, "#{k.strftime("%B, %Y")} = #{v}"]
        end
        prev_key = k
      end

      render partial: 'chart'
    end

    def bot
      @messages_count = LoggedUserMessage.count
    end

    private

    def monthly_active_users
      [
        Comment.where('created_at > ?', 1.month.ago)
          .uniq.count(:user_id),
        Share.where('created_at > ?', 1.month.ago)
          .uniq.count(:user_id),
        ActsAsVotable::Vote.where('created_at > ?', 1.month.ago)
          .uniq.count(:voter_id)
      ].max
    end

    def percentage value, total
      "#{'%.2f' % (value / total.to_f * 100)}%"
    end
  end
end
