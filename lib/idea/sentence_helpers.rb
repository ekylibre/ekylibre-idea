# frozen_string_literal: true

module Idea
  # HTML formatting helpers used by Idea::Components::*#next_question to
  # build the `sentence:` field.
  module SentenceHelpers
    # Wraps a message in an information banner (info icon + text on a tinted
    # block); styled by `.idea-information` in
    # app/assets/stylesheets/idea/main.scss.
    #
    # @param msg [String] the message body (already i18n'd, may contain HTML)
    # @return [String] HTML snippet
    def idea_information_tag(msg)
      "<div class='idea-information'>" \
        "<i style='color: #3340A4;' class='icon icon-help-outline'></i> #{msg}" \
      "</div>"
    end
  end
end
