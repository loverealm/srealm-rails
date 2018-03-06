class OpentokService
  def self.connection
    service.connection
  end
  
  def self.service
    @_connection ||= OpenTok::OpenTok.new ENV['OPENTOK_KEY'], ENV['OPENTOK_SECRET']
  end
  
  def self.web_token
    payload = {
        iss: ENV['OPENTOK_KEY'],
        ist: 'project',
        iat: Time.current.to_i,
        exp: 2.minutes.from_now.to_i
      }
    JWT.encode payload, ENV['OPENTOK_SECRET'], 'HS256'
  end
  
  def self.curl(params = nil)
    headers = {'X-OPENTOK-AUTH'=>web_token, 'Content-Type'=>'application/json'}
    r = Faraday.new(url: "https://api.opentok.com/", headers: headers, params: params)
  end
end