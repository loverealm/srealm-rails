class RedirectOutgoingMails
  class << self
    def delivering_email(mail)
      if !Rails.env.production?
        Rails.logger.info "******* TESTER_WHITE_EMAILS: #{ENV['TESTER_WHITE_EMAILS'].to_s.split(',').inspect} ==== #{mail.to}"
        mail.to = [mail.to] unless mail.to.is_a?(Array)
        mail.to = mail.to.map{|e| ENV['TESTER_WHITE_EMAILS'].to_s.split(',').include?(e) ? e : ENV['TESTER_EMAIL'] || 'loverealm.staging@gmail.com' }
      end
    end
  end
end