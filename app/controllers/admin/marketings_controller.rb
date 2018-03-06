module Admin
  class MarketingsController < BaseController
    # show settings edit form
    def index
    end

    def send_email
      users = User.valid_users
      users = User.where(email: params[:test_email].split(',')) if params[:test_email].present?
      Thread.abort_on_exception=false
      Thread.new do
        users.find_each do |user|
          UserMailer.send_message(user, params[:subject], params[:message] + (params[:include_copyright] ? email_copyright(user) : '')).deliver_later
        end
      end
      
      unless users.any?
        render(json: { errors: ['No users found'] }, status: :unprocessable_entity)
      else
        render_success_message("Send emails is in progress... (#{users.count} users), this process can take some minutes depending of the quantity of users.")
      end
    end
    
    def download_numbers
      send_data User.valid_users.pluck(:phone_number).delete_if{|p| !p.present? }.join("\n"), filename: 'phone-numbers-list.txt' 
    end
    
    def send_message
      Thread.abort_on_exception=false
      Thread.new do
        User.valid_users.find_each do |user|
          current_user.send_message_to(user, params[:message])
        end
      end
      render_success_message('Send messages is in progress..., this process can take some minutes depending of the quantity of users.')
    end
    
  end
end
