module Idea
  module Components
    class Base

      # @params [Integer] diagnostic_id : IdeaDiagnostic id
      #  @params [String] indicator : component idea_id
      def initialize(diagnostic_id: nil, idea_name: nil)
        @idea_diagnostic = IdeaDiagnostic.find_by_id(diagnostic_id)
        @idea_diagnostic_item = @idea_diagnostic.idea_diagnostic_items.find_by(idea_id: idea_name)
        @campaign = @idea_diagnostic.campaign
      end

      private

        # @params [String] idea_id: component name
        # Alias for @idea_diagnostic_item_values.find_by_name
        # @return [IdeaDiagnosticItemValue]
        def item(idea_id)
          @idea_diagnostic_item.idea_diagnostic_item_values.find_by(name: idea_id)
        end

        # @params [String] idea_id: component name
        # Sets to nil all idea_diagnostic_item_values for an indicator
        def reset_item_values(idea_name)
          (1..Idea::Indicators.item_values_count(idea_name)).each do |num|
            item("#{idea_name}_#{num}").set!(nil, :string)
          end
        end

        # @params [String] idea_name: component name downcased
        # @returns [Array] list of all item_values that can be autofilled
        def autofillables(idea_name)
          self.methods.select{|method| method.match("#{idea_name}_")}
        end

        # @params [String] idea_name: component name downcased
        # Ensures all autofillables item_values have values
        def autofilled?(idea_name)
          autofillables(idea_name).none? do |item_value|
            item(item_value.upcase).value.nil?
          end
        end

        # @returns [Array]: list of all idea varieties
        def idea_varieties
          %w[field_industrial_fodder_crops_idea vineyard_idea arboricultural_idea].map do |cgi|
            Onoma::CropSet.find(cgi).varieties
          end.flatten
        end

        # @returns [Array]: list of all sheltered gardening varieties
        def sheltered_gardening_varieties
          Onoma::CropSet.find('sheltered_gardening_idea').varieties
        end

    end
  end
end
