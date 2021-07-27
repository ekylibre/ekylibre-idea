class DiagnosticInstigator

  def initialize(idea_diagnostic)
    @idea_diagnostic = idea_diagnostic
  end

  def instigate
    create_functional_diversity_items
    @idea_diagnostic.idea_diagnostic_items.each do |item|
      create_diagnostic_item_values(item)
    end
    IdeaAutofillJob.perform_later(@idea_diagnostic.id)
  end

  private

    def create_functional_diversity_items
      Idea::Indicators.functional_diversity_attributes.each do |fd_attrs|
        IdeaDiagnosticItem.create(
          {
            idea_diagnostic: @idea_diagnostic,
            group: 'functional_diversity'
          }.merge(fd_attrs)
        )
      end
    end

    def create_diagnostic_item_values(item)
      (1..Idea::Indicators.item_values_count(item.idea_id)).each do |id|
        IdeaDiagnosticItemValue.create(idea_diagnostic_item: item, name: "#{item.idea_id}_#{id}")
      end
    end

end
