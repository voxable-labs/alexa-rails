module Alexa
  class Request
    attr_accessor :body, :params

    def initialize(request)
      @req = request
      @body = request.body
      @params = if request.body.size > 0
                  request.body.rewind
                  JSON.parse(request.body.read).with_indifferent_access
                else
                  {}
                 end
    end

    def application_id
      application_id   = session.application_id
      application_id ||= context['System']['application']['applicationId']

      application_id
    end

    def user_id
      user_id   = session.user_id
      user_id ||= context['System']['application']['userId']

      user_id
    end

    # @return [String]
    #   The type of the Alexa request.
    def type
      params["request"]["type"]
    end

    def intent_request?
      type == "IntentRequest"
    end

    def launch_request?
      type == "LaunchRequest"
    end

    def session_ended_request?
      type == "SessionEndedRequest"
    end

    # @return [Boolean]
    #   true if this is a Plackback Controller request
    def playback_request?
      type.include?("PlaybackController")
    end

    # @return [Boolean]
    #   true if this is a Permission Accepted request
    #
    # @see https://developer.amazon.com/en-US/docs/alexa/smapi/skill-events-in-alexa-skills.html#skill-disabled-event
    def permission_accepted?
      type == "AlexaSkillEvent.SkillPermissionAccepted"
    end

    def help_request?
      intent_request? && intent_name == "AMAZON.HelpIntent"
    end

    def cancel_request?
      intent_request? && intent_name == "AMAZON.CancelIntent"
    end

    def session
      @_session ||= Alexa::Session.new(params && params["session"].dup)
    end

    def slots
      @_slots ||= begin
                    if intent_request?
                      return [] if help_request?
                      return [] if cancel_request?

                      params["request"]["intent"]["slots"]
                        .inject(HashWithIndifferentAccess.new) do |hash, slot|
                        name = slot[0]
                        data = slot[1]
                        hash[name] = Alexa::Slot.new(data)
                        hash
                      end
                    else
                      []
                    end
                  end
    end

    def dialog_state
      params["request"]["dialogState"]
    end

    def valid?
      Alexa.configuration.skill_ids.include?(application_id)
    end

    def intent_name
      return nil if !intent_request?
      params["request"]["intent"]["name"]
    end

    def locale
      params["request"]["locale"]
    end

    # @return [Hash]
    #   The Alexa request context.
    def context
      params["context"]
    end
  end
end
