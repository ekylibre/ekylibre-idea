class IdeaAutofillJob < ApplicationJob
  queue_as :default

  def perform(diagnostic_id, indicator: nil)
    @idea_diagnostic = IdeaDiagnostic.find_by_id(diagnostic_id)
    components = indicator.nil? ? Idea::Indicators.components : [indicator]
    components.each do |component|
      klaas = "Idea::Components::#{component}".constantize.new(diagnostic_id: diagnostic_id)
      idea_item = @idea_diagnostic.idea_diagnostic_items.find_by(idea_id: component)
      (1..Idea::Indicators.item_values_count(component)).to_a.each do |item_value|
        value_name = "#{component}_#{item_value}"
        begin
          item_value = idea_item.idea_diagnostic_item_values.find_by(name: value_name)
          value = klaas.send(value_name.downcase)
          item_value.set!(value, value.class.to_s.downcase)
        rescue NoMethodError => e
          nil
        end
      end
    end
  end

end
