module Alexa
  class Response
    attr_accessor :intent, :directives, :locals, :device,
      :audio_url, :audio_play_behavior, :audio_token,
      :audio_expected_previous_token, :audio_offset,
      :audio_title, :audio_subtitle, :audio_foreground_image_url,
      :audio_background_image_url

    module Directives
      RENDER_DOCUMENT = "Alexa.Presentation.APL.RenderDocument"
    end

    def initialize(intent:, directives: [], device:)
      @intent = intent
      @directives = directives
      @device = device
      @locals = Hash[intent.instance_variables.collect { |v| [v, intent.instance_variable_get(v)] }]
      @slots_to_not_render_elicitation = []
    end

    def with(template: )
      # TODO make this return a new object instead of self.
      @force_template_filename = template
      self
    end

    # Marks a slot for elicitation.
    #
    # Options:
    #  - skip_render: Lets you skip the rendering of the elicited slot's view.
    #                 Helpful when you have the elication text already in the
    #                 response and don't wanna override it.
    def elicit_slot!(slot_to_elicit, skip_render: false)
      directives << {
        type: "Dialog.ElicitSlot",
        slotToElicit: slot_to_elicit
      }

      if skip_render
        @slots_to_not_render_elicitation << slot_to_elicit
      end
    end

    def partial_path(format: :ssml, filename: nil)
      if elicit_directives.any?
        slot_to_elicit = elicit_directives.first[:slotToElicit]
      end

      if filename.nil? && @force_template_filename.present?
        filename = @force_template_filename
      end

      # Determine the correct filename extension for the partial.
      format_extension = format.to_s
      format_extension = "json" if format == :apl

      if filename.present?
        "#{partials_directory}/#{filename}.#{format_extension}.erb"
      else
        if slot_to_elicit.present? && !@slots_to_not_render_elicitation.include?(slot_to_elicit)
          "#{partials_directory}/elicitations/#{slot_to_elicit.underscore}.#{format_extension}.erb"
        else
          "#{partials_directory}/default.#{format_extension}.erb"
        end
      end
    end

    def partials_directory
      @_partials_directory ||= "alexa/#{intent.context.locale.downcase}/intent_handlers/"\
        "#{intent_directory_name}"
    end

    def elicit_directives
      return [] if directives.empty?
      directives.select { |directive| directive[:type] == "Dialog.ElicitSlot" }
    end

    # Mark this response as using an AudioPlayer interface directive.
    #
    # @return [self]
    def audio_player!
      @audio_player = true
      self
    end

    # @return [Boolean]
    #   true if this is an AudioPlayer directive response
    def audio_player?
      @audio_player == true
    end

    # Direct the Alexa service to keep any information on the screen for 30 seconds
    # without opening the mic by keeping shouldEndSession undefined.
    #
    # @return [self]
    def keep_screen_active!
      @keep_screen_active = true
      self
    end

    # @return [Boolean]
    #   true if the screen should stay active
    def keep_screen_active?
      @keep_screen_active == true
    end

    def keep_listening!
      @keep_listening = true
      self
    end

    def keep_listening?
      @keep_listening == true
    end

    def end_session?
      return false if keep_listening?
      return false if elicit_directives.any?
      return true
    end

    def intent_directory_name
      # respects namespacing.
      # For example +Alexa::IntentHandlers::MyNameSpace::IntentName+
      # will return +my_name_space/intent_name+.
      intent.class.name.split("::").drop(2).join("::").underscore
    end
  end
end
