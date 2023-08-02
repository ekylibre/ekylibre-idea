module Idea
  class Indicators
    class << self
      def functional_diversity_attributes
        [{
          idea_id: 'A1',
          treshold: '5',
          name: 'Diversité des espèces cultivées'
        },
         {
           idea_id: 'A2',
           treshold: '5',
           name: 'Diversité génétique'
         },
         {
           idea_id: 'A3',
           treshold: '5',
           name: 'Diversité temporelle des cultures'
         },
         {
           idea_id: 'A4',
           treshold: '5',
           name: 'Qualité de l’organisation spatiale'
         },
         {
           idea_id: 'A5',
           treshold: '5',
           name: 'Diversité des espèces cultivées'
         }]
      end

      def item_values_count(idea_id)
        {
          A1: 12,
          A2: 28,
          A3: 14,
          A4: 26,
          A5: 6
        }[idea_id.to_sym]
      end

      def components
        %w[A1 A2 A3 A4 A5]
      end
    end

  end
end
