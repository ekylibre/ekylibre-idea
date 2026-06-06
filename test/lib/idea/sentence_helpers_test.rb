# frozen_string_literal: true

require 'test_helper'
require 'idea/sentence_helpers'

class IdeaSentenceHelpersTest < Minitest::Test
  # Bare host so the module's behavior can be tested in isolation,
  # without loading Idea::Components::Base.
  class Host
    include Idea::SentenceHelpers
  end

  def setup
    @host = Host.new
  end

  def test_idea_information_tag_wraps_message_in_info_banner
    html = @host.idea_information_tag('Surface en herbe : 18 ha')

    assert_includes html, "class='idea-information'"
    assert_includes html, "class='icon icon-help-outline'"
    assert_includes html, 'Surface en herbe : 18 ha'
  end

  def test_idea_information_tag_does_not_escape_html_in_message
    # Mirrors the prior contract — callers already inject HTML chunks
    # (i18n + nested idea_information_tag calls). Escaping here would
    # double-encode the existing markup. Sanitization is a view-layer
    # concern, not the helper's.
    html = @host.idea_information_tag('<strong>x</strong>')
    assert_includes html, '<strong>x</strong>'
  end
end
