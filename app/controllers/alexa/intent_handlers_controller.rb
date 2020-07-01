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
          when 'AMAZON.FallbackIntent'
            @display_card = false
            @resp = Alexa::IntentHandlers::Fallback.new(alexa_context).handle
          when 'AMAZON.PauseIntent'
            use_pause_intent
          when 'AMAZON.ResumeIntent'
            use_resume_intent
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
        elsif alexa_request.playback_request?
          case alexa_request.type
          when 'PlaybackController.PlayCommandIssued'
            use_resume_intent
          when 'PlaybackController.PauseCommandIssued'
            use_pause_intent
          end
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

    private def use_resume_intent
      @display_card = false
      @resp = Alexa::IntentHandlers::Resume.new(alexa_context).handle
    end

    private def use_pause_intent
      @display_card = false
      @resp = Alexa::IntentHandlers::Pause.new(alexa_context).handle
    end
  end
end
