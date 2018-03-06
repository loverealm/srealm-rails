module OpenTok
  class OpenTok
    def connection
      client
    end
  end
  
  class Client
    # Sample: https://tokbox.com/developer/rest/#start_broadcast
    def start_broadcast(session_id, opts = {})
      opts.extend(HashExtensions)
      body = { "sessionId" => session_id }.merge(opts.camelize_keys!)
      response = self.class.post("/v2/project/#{@api_key}/broadcast", {
          :body => body.to_json,
          :headers => generate_headers("Content-Type" => "application/json")
      })
      puts "!!!!!!!!!!!!!!!!!!!!!: #{response.inspect}"
      case response.code
        when 200
          response.parsed_response
        when 400
          raise "The Broadcast could not be started. The request was invalid or the session has no connected clients."
        when 403
          raise "Authentication failed while starting an broadcast. API Key: #{@api_key}"
        when 404
          raise "The Broadcast could not be started. The Session ID does not exist: #{session_id}"
        when 409
          raise "The Broadcast could not be started. The session could be peer-to-peer or the session is already being recorded."
        else
          raise "The Broadcast could not be started"
      end
    rescue StandardError => e
      raise OpenTokError, "Failed to connect to OpenTok. Response code: #{e.message}"
    end
    
    # sample: https://tokbox.com/developer/rest/#stop_broadcast
    def stop_broadcast(broadcast_id)
      response = self.class.post("/v2/project/#{@api_key}/broadcast/#{broadcast_id}/stop", {
          :headers => generate_headers("Content-Type" => "application/json")
      })
      puts "!!!!!!!!!!!!!!!!!!!!!: #{response.inspect}"
      case response.code
        when 200
          response.parsed_response
        when 400
          raise "The Broadcast could not be stopped. The request was invalid."
        when 403
          raise "Authentication failed while stopping an broadcast. API Key: #{@api_key}"
        when 404
          raise "The Broadcast could not be stopped. The Broadcast ID does not exist: #{broadcast_id}"
        when 409
          raise "The Broadcast could not be stopped. The Broadcast is not currently recording."
        else
          raise "The Broadcast could not be stopped."
      end
    rescue StandardError => e
      raise OpenTokError, "Failed to connect to OpenTok. Response code: #{e.message}"
    end

    # https://tokbox.com/developer/rest/#get_info_broadcast
    def get_broadcast(broadcast_id)
      response = self.class.get("/v2/project/#{@api_key}/broadcast/#{broadcast_id}", {
          :headers => generate_headers
      })
      puts "!!!!!!!!!!!!!!!!!!!!!: #{response.inspect}"
      case response.code
        when 200
          response.parsed_response
        when 400
          raise "The broadcast could not be retrieved. The broadcast ID was invalid: #{broadcast}"
        when 403
          raise "Authentication failed while retrieving an broadcast. API Key: #{@api_key}"
        else
          raise "The broadcast could not be retrieved."
      end
    rescue StandardError => e
      raise OpenTokError, "Failed to connect to OpenTok. Response code: #{e.message}"
    end

    # https://tokbox.com/developer/rest/#change_live_streaming_layout
    def change_layout_broadcast(broadcast_id, opts = {})
      body = { "sessionId" => session_id }.merge(opts.camelize_keys!)
      response = self.class.put("/v2/project/#{@api_key}/broadcast/#{broadcast_id}/layout", {
          :body => body.to_json,
          :headers => generate_headers
      })
      puts "!!!!!!!!!!!!!!!!!!!!!: #{response.inspect}"
      case response.code
        when 200
          response.parsed_response
        when 400
          raise "The broadcast could not be changed. The broadcast ID was invalid: #{broadcast}"
        when 403
          raise "Authentication failed while retrieving an broadcast. API Key: #{@api_key}"
        else
          raise "The broadcast layout could not be changed."
      end
    rescue StandardError => e
      raise OpenTokError, "Failed to connect to OpenTok. Response code: #{e.message}"
    end
    
  end
end