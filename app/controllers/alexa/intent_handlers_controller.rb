require_dependency "alexa/application_controller"

module Alexa
  class IntentHandlersController < ApplicationController
    include Alexa::ContextHelper
    include Alexa::RenderHelper
    skip_before_action :verify_authenticity_token

    def create
      @resp = nil
      @display_card = true

      if alexa_request.valid?
        if alexa_request.intent_request?
          case alexa_request.intent_name
          when 'AMAZON.CancelIntent'
            @display_card = false
            @resp = Alexa::IntentHandlers::GoodBye.new(alexa_context).handle
          when 'AMAZON.StopIntent'
            @display_card = false
            @resp = Alexa::IntentHandlers::GoodBye.new(alexa_context).handle
          when 'AMAZON.HelpIntent'
            @resp = Alexa::IntentHandlers::Help.new(alexa_context).handle
          else
            @resp = "Alexa::IntentHandlers::#{alexa_request.intent_name}"
              .constantize
              .new(alexa_context)
              .handle
          end
        elsif alexa_request.launch_request?
          @resp = Alexa::IntentHandlers::LaunchApp.new(alexa_context).handle
        elsif alexa_request.session_ended_request?
          @display_card = false
          @resp = Alexa::IntentHandlers::SessionEnd.new(alexa_context).handle
        end
      end

      alexa_response = @resp
      respond_for_alexa_with(alexa_response)
    end

    helper_method def intent
      @resp.intent
    end

    helper_method def slots
      intent.slots
    end

    helper_method def context
      alexa_context
    end
  end
end
