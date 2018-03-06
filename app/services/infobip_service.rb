class InfobipService
  class << self
    def send_invitation_sms phone_number, user
      sms = OneApi::SMSRequest.new
      sms.sender_name =  user.full_name.gsub(/\s+/, "")#I18n.translate('sms.sender_name')
      sms.sender_address = user.full_name.gsub(/\s+/, "")#I18n.translate('sms.sender_name')
      sms.address = phone_number.gsub(/[\+\s]+/, '')
      sms.message = I18n.translate('sms.message.invitation', username: user.full_name)
      before_send(sms)
      sms_client.send_sms(sms)
    end

    def send_message_to(phone_number, message, from = 'LoveRealm')
      return unless phone_number.present?
      sms = OneApi::SMSRequest.new
      sms.sender_name = from.gsub(/\s+/, "")
      sms.sender_address = from.gsub(/\s+/, "")
      sms.address = phone_number.gsub(/[\+\s]+/, '')
      sms.message = message
      before_send(sms)
      sms_client.send_sms(sms)
    end
    handle_asynchronously :send_message_to

    def sms_client
      @sms_client ||= begin
        raise "Infobip credentials are missing" unless ENV['LR_INFOBIP_USERNAME'] && ENV['LR_INFOBIP_PASSWORD']
        OneApi::SmsClient.new(ENV['LR_INFOBIP_USERNAME'], ENV['LR_INFOBIP_PASSWORD'])
      end
    end

    def sms_logger
      @sms_logger ||= Logger.new("#{Rails.root}/log/sms.log")
    end
    
    def before_send(sms)
      sms.address = (ENV['TESTER_PHONE'] || '+591 79716902').to_s.gsub(/[\+\s]+/, '') if !Rails.env.production? && !ENV['TESTER_WHITE_PHONES'].to_s.split(',').include?(sms.address)
      sms_logger.info("Sending sms to: #{sms.address}")
    end
    
    # calculate the total cost to send a sms
    # @return (Float): total cost
    def calculate_cost(phone_numbers, message)
      phone_numbers.map{|n|
        case Phonelib.parse(n).country
          when 'US'
            0.07
          when 'GH'
            0.027
          when 'UK'
            0.12
          else
            0.20 # todo: calculate price for other countries
        end
      }.sum
      
      # phone_numbers.each_slice(10000).to_a.map{|numbers| calculate_partial_cost(numbers, message) }.sum
    end
    
    private
    # calculate the partial total cost to send a sms
    # @return (Float): total of cost
    def calculate_partial_cost(phone_numbers, message)
      requested_url = 'https://api.txtlocal.com/send/?'
      uri = URI.parse(requested_url)
      http = Net::HTTP.start(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      res = Net::HTTP.post_form(uri, 'apikey' => ENV['LR_TXTLOCAL_TOKEN'], 'message' => message, 'sender' => 'Test', 'numbers' => phone_numbers.join(','), 'test' => '1')
      response = JSON.parse(res.body)
      response['cost']
    end
  end
end
