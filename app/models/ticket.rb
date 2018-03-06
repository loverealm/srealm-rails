class Ticket < ActiveRecord::Base
  belongs_to :event
  belongs_to :user
  belongs_to :payment
  validates_presence_of :event, :user_id

  # marks as redeemed the current ticket
  def redeem!
    return errors.add(:base, 'This ticked was already redeemed.') && false if is_redeemed?
    update_column(:redeemed_at, Time.current)
  end

  # check if current ticket is already redeemed
  def is_redeemed?
    redeemed_at?
  end

  # generate ticket code
  def generate_code!
    code = Base64.encode64(ApplicationHelper.encrypt_text("#{event_id}-#{id}")).gsub("\n", '')
    qrcode = RQRCode::QRCode.new("#{code}")
    update(png: qrcode.as_png.to_data_url, code: code)
    send_email!
  end

  # send email to the user with the qr code
  def send_email!
    UserMailer.event_ticket_notification(user, self).deliver_now
  end
end