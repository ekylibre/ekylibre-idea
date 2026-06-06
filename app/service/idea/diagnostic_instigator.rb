# frozen_string_literal: true

module Idea
  # Creates one IdeaDiagnosticItem per IDEA4 indicator (53 total across
  # dimensions A/B/C) plus their backing IdeaDiagnosticItemValue
  # placeholders, then enqueues the autofill job. Invoked from
  # Backend::IdeaDiagnosticsController#create.
  #
  # The previous implementation only seeded the 5 "functional_diversity"
  # indicators (A1-A5); it now iterates over the full registry loaded
  # from config/indicators.yml.
  class DiagnosticInstigator
    def initialize(idea_diagnostic)
      @idea_diagnostic = idea_diagnostic
    end

    def instigate
      create_indicator_items
      @idea_diagnostic.idea_diagnostic_items.each do |item|
        create_diagnostic_item_values(item)
      end
      IdeaAutofillJob.perform_later(@idea_diagnostic.id)
    end

    private

      def create_indicator_items
        Idea::Indicators.all_item_attributes.each do |attrs|
          IdeaDiagnosticItem.create(attrs.merge(idea_diagnostic: @idea_diagnostic))
        end
      end

      # Names without zero-padding ("A2_1", "A4_9", "C11_2") — components
      # and controllers normalize incoming padded forms via
      # Idea::Indicators.normalize_item_value_name.
      def create_diagnostic_item_values(item)
        count = Idea::Indicators.item_values_count(item.idea_id) || 0
        (1..count).each do |id|
          IdeaDiagnosticItemValue.create(
            idea_diagnostic_item: item,
            name: "#{item.idea_id}_#{id}"
          )
        end
      end
  end
end
