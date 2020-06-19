##
# This class represents the +device+ part in the request.
#
module Alexa
  class Device
    attr_accessor :attributes
    def initialize(attributes: {}, context:)
      @attributes = attributes
      @context = context
    end

    ##
    # Return device id
    def id
      attributes["deviceId"]
    end

    # @return [Array<String>]
    #   Supported display interfaces for this user's device.
    #
    # @see https://developer.amazon.com/en-US/docs/alexa/alexa-presentation-language/apl-support-for-your-skill.html#detect-apl
    def supported_interfaces
      attributes["supportedInterfaces"]
    end

    # @return [Boolean]
    #   true if device supports AudioPlayer interface
    def audio_supported?
      supported_interfaces.has_key?("AudioPlayer")
    end

    # @return [Boolean]
    #   true if device supports video
    def video_supported?
      supported_interfaces.has_key?("VideoApp")
    end

    # @return [Boolean]
    #   true if device supports APL
    def apl_supported?
      supported_interfaces.has_key?(Response::Directives::RENDER_DOCUMENT)
    end

    ##
    # Return device location from amazon.
    # Makes an API to amazon alexa's device location service and returns the
    # location hash
    def location
      @_location ||= begin
        if Alexa.configuration.location_permission_type == :full_address
          get_address
        elsif Alexa.configuration.location_permission_type == :country_and_postal_code
          get_address(only: :country_and_postal_code)
        end
      end
    end

    private

    def get_address(only: nil)
      url = "#{@context.api_endpoint}/v1/devices/#{id}/settings/address"
      url = url + "/countryAndPostalCode" if only == :country_and_postal_code
      conn = Faraday.new(url: url) do |conn|
        conn.options["open_timeout"] = 2
        conn.options["timeout"] = 3
        conn.adapter :net_http
        conn.headers["Authorization"] = "Bearer #{@context.api_access_token}"
      end
      resp = conn.get
      if resp.status == 200
        return JSON.parse(resp.body)
      end
    end
  end
end
