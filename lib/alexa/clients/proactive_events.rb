require 'httparty'

module Alexa
  module Clients
    # Proactive events API client.
    #
    # @see https://developer.amazon.com/en-US/docs/alexa/smapi/proactive-events-api.html
    class ProactiveEvents
      include HTTParty

      DEFAULT_BASE_URL = 'https://api.amazonalexa.com/'
      ACCESS_TOKEN_REQUEST_URL = 'https://api.amazon.com/auth/o2/token'
      PROACTIVE_EVENTS_DEV_PATH = '/v1/proactiveEvents/stages/development'
      PROACTIVE_EVENTS_PROD_PATH = '/v1/proactiveEvents/'

      def initialize(base_url = nil)
        # Set the base URI
        self.class.base_uri(base_url || DEFAULT_BASE_URL)
      end

      # Create a message alert broadcast event.
      #
      # @param [String] broadcast_id
      #   A unique ID used to reference this broadcast.
      # @param [DateTime, ActiveSupport::TimeWithZone] timestamp
      #   The timestamp for this broadcast event. (default: now)
      # @param [DateTime, ActiveSupport::TimeWithZone] expiry
      #   When this broadcast expires. (default: 24 hours from now)
      # @return [String] status
      #   The status of the message alert. One of `'UNREAD'`, `'FLAGGED'`.
      # @return [String] freshness
      #   The freshness of the message. One of `'NEW'`, `'OVERDUE'`.
      # @return [String] creator_name
      #   The name of the creator of the message group.
      # @return [Integer] message_count
      #   The count of messages in the group.
      # @param [Array] localized_attributes
      #   Any localized attributes. (default: [])
      # @param [String] client_id
      #   The Amazon API client ID for this skill.
      # @param [String] client_secret
      #   The Amazon API client secret for this skill.
      # @param [Boolean] production
      #   Whether or not to use production API endpoints. (default: false)
      #
      # @return [HTTParty::Response]
      #   The proactive events API response.
      def create_message_alert_broadcast(
          broadcast_id:,
          timestamp: nil,
          expiry: nil,
          status:,
          freshness:,
          creator_name:,
          message_count:,
          localized_attributes: [],
          client_id:,
          client_secret:,
          production: false
      )
        # Construct a message alert broadcast.
        event = message_alert_event(
                  status: status,
                  freshness: freshness,
                  creator_name: creator_name,
                  message_count: message_count
                )
        message_alert_event =
            broadcast_event_body(
                broadcast_id: broadcast_id,
                timestamp: timestamp,
                expiry: expiry,
                event: event
            )

        # Send the broadcast event API request.
        create_broadcast_event(
            event: message_alert_event,
            localized_attributes: localized_attributes,
            client_id: client_id,
            client_secret: client_secret,
            production: production
        )
      end

      # Create a broadcast event.
      #
      # @param [Hash] event
      #   The event object.
      # @param [Array] localized_attributes
      #   Any localized attributes. (default: [])
      # @param [String] client_id
      #   The Amazon API client ID for this skill.
      # @param [String] client_secret
      #   The Amazon API client secret for this skill.
      # @param [Boolean] production
      #   Whether or not to use production API endpoints. (default: false)
      #
      # @see https://developer.amazon.com/en-US/docs/alexa/smapi/proactive-events-api.html#call-proactive
      #
      # @return [HTTParty::Response]
      #   The proactive events API response.
      def create_broadcast_event(
          event:,
          localized_attributes: [],
          client_id:,
          client_secret:,
          production: false)

        # Request an API access token.
        token_response = request_api_token(client_id, client_secret)
        access_token = token_response.parsed_response['access_token']

        # Select the appropriate endpoint, based on environment.
        broadcast_path =
            production ? PROACTIVE_EVENTS_PROD_PATH : PROACTIVE_EVENTS_DEV_PATH

        # Set up request options.
        options = {
            headers: {
                'Authorization': "Bearer #{access_token}",
                'Content-Type': 'application/json'
            },
            body: event.to_json
        }

        # Send request.
        self.class.post(broadcast_path, options)
      end

      # Generate a broadcast event request body.
      #
      # @param [String] broadcast_id
      #   A unique ID used to reference this broadcast.
      # @param [DateTime] timestamp
      #   The timestamp for this broadcast event. (default: now)
      # @param [DateTime] expiry
      #   When this broadcast expires. (default: 24 hours from now)
      # @param [Hash] event
      #   The broadcast event.
      #
      # @return [Hash]
      #   The broadcast event body.
      private def broadcast_event_body(
          broadcast_id:,
          timestamp: nil,
          expiry: nil,
          event:)
        # Set default for timestamp and expiry.
        expiry ||= 24.hours.from_now
        timestamp ||= Time.now

        {
            timestamp: timestamp.utc.iso8601,
            referenceId: broadcast_id,
            expiryTime: expiry,
            event: event,
            relevantAudience: {
                type: "Multicast",
                payload: {}
            }
        }
      end

      # Generate a message alert event.
      #
      # @return [String] status
      #   The status of the message alert. One of `'UNREAD'`, `'FLAGGED'`.
      # @return [String] freshness
      #   The freshness of the message. One of `'NEW'`, `'OVERDUE'`.
      # @return [String] creator_name
      #   The name of the creator of the message group.
      # @return [Integer] message_count
      #   The count of messages in the group.
      #
      # @see https://developer.amazon.com/en-US/docs/alexa/smapi/schemas-for-proactive-events.html#message-alert
      #
      # @return [Hash]
      #   The message alert event.
      private def message_alert_event(status:, freshness:, creator_name:, message_count:)
        {
            name: "AMAZON.MessageAlert.Activated",
            payload: {
                state: {
                    status: status,
                    freshness: freshness
                },
                messageGroup: {
                    creator: {
                        name: creator_name
                    },
                    count: message_count
                }
            }
        }
      end

      # Request an API token for using the proactive events API. Will be valid
      # for one hour after issuance.
      #
      # @param [String] client_id
      #   The skill's client ID.
      # @param [String] client_secret
      #   The skill's client secret.
      # @param [Hash] options
      #   Any additional options to pass to the API call.
      #
      # @see https://developer.amazon.com/en-US/docs/alexa/smapi/proactive-events-api.html#request-format
      #
      # @return [HTTParty::Response]
      #   The Proactive Events API access token response.
      def request_api_token(client_id, client_secret, options = {})
        options.merge!({
          body: {
            grant_type: 'client_credentials',
            client_id: client_id,
            client_secret: client_secret,
            scope: 'alexa::proactive_events'
          }
        })

        HTTParty.post(ACCESS_TOKEN_REQUEST_URL, options)
      end
    end
  end
end
