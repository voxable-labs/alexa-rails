module Alexa
  module Helpers
    # @see https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs/blob/2.0.x/ask-sdk-core/lib/util/SsmlUtils.ts
    # @see https://github.com/alexa/alexa-skills-kit-sdk-for-nodejs/blob/7a4f215dea1b5383f61dae4674d31ba867b5bb53/ask-sdk-core/tst/util/SsmlUtils.spec.ts
    module SSML
      INVALID_XML_CHARACTERS_MAPPING = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&apos;'
      }

      module_function

      # Escape the XML characters that will make an invalid SSML response.
      #
      # @param [String] ssml
      #   The SSML to escape.
      def escape_xml_characters(ssml)
        # Sanitize any already escaped character to ensure they are not
        # escaped more than once.
        sanitized_input = ssml.gsub(/&amp;|&lt;|&gt;|&quot;|&apos;/, '')

        ssml.gsub(/([&'"><])/) { |c| INVALID_XML_CHARACTERS_MAPPING[c] }
      end
    end
  end
end
