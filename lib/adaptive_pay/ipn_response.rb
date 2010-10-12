module AdaptivePay
  class IpnResponse
    cattr_accessor :mode
    self.mode = :production

    def base_page_url
      environments = {
        :production => "https://www.paypal.com",
        :test       => "https://www.sandbox.paypal.com"
      }
      environments[self.mode]
    end

    def initialize(params, raw_post)
      @params = params
      @raw    = raw_post
    end

    def valid?
      uri = URI.parse(base_page_url + '/webscr?cmd=_notify-validate')

      http = Net::HTTP.new(uri.host, uri.port)
      http.open_timeout = 60
      http.read_timeout = 60
      http.verify_mode  = OpenSSL::SSL::VERIFY_NONE
      http.use_ssl = true
      response = http.post(uri.request_uri, @raw,
                           'Content-Length' => "#{@raw.size}",
                           'User-Agent' => "My custom user agent").body

      raise StandardError.new("Faulty paypal result: #{response}") unless ["VERIFIED", "INVALID"].include?(response)
      raise StandardError.new("Invalid IPN: #{response}") unless response == "VERIFIED"

      true
    end

    def completed?
      status == "COMPLETED"
    end
  end
end
