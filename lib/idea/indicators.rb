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

      # Subset of components that drive a wizard questionnaire (each has a
      # non-empty next_question branch tree). The complement — A3 and A5 —
      # is autofill-only and shows no .idea_duke button in the dashboard.
      def scripted_components
        %w[A1 A2 A4]
      end

      # Storage nature each item_value expects, mirroring how compute_score
      # consumes the value in lib/idea/components/*.rb. Inputs whose name
      # isn't listed fall back to "string". Used by the controller to coerce
      # the user's answer into the right column (boolean_value /
      # integer_value / float_value / string_value) so downstream arithmetic
      # in update_global_score doesn't blow up on a String / 100.0 op.
      NATURE_MAP = {
        # A1
        'A1_1'  => 'boolean', 'A1_2'  => 'integer', 'A1_3'  => 'integer',
        'A1_4'  => 'integer', 'A1_5'  => 'integer', 'A1_6'  => 'integer',
        'A1_7'  => 'integer', 'A1_8'  => 'boolean', 'A1_9'  => 'integer',
        'A1_10' => 'integer', 'A1_11' => 'integer', 'A1_12' => 'integer',
        # A2
        'A2_1'  => 'boolean', 'A2_2'  => 'boolean', 'A2_3'  => 'boolean',
        'A2_4'  => 'boolean', 'A2_5'  => 'integer', 'A2_6'  => 'boolean',
        'A2_7'  => 'boolean', 'A2_8'  => 'boolean', 'A2_9'  => 'boolean',
        'A2_10' => 'boolean', 'A2_11' => 'boolean', 'A2_12' => 'integer',
        'A2_13' => 'boolean', 'A2_14' => 'boolean', 'A2_15' => 'integer',
        'A2_16' => 'boolean', 'A2_17' => 'float',   'A2_18' => 'boolean',
        'A2_19' => 'boolean', 'A2_20' => 'boolean', 'A2_21' => 'boolean',
        'A2_22' => 'boolean', 'A2_24' => 'boolean', 'A2_25' => 'boolean',
        'A2_27' => 'float',   'A2_28' => 'boolean',
        # A4
        'A4_9'  => 'boolean', 'A4_10' => 'float',   'A4_16' => 'float',
        'A4_17' => 'float',   'A4_20' => 'float',   'A4_21' => 'float'
      }.freeze

      def nature_for(item_value_name)
        NATURE_MAP[normalize_item_value_name(item_value_name)] || 'string'
      end

      # Strip the legacy zero-padded numeric suffix that the components
      # emit in `next_indicator` (e.g. `A2_01`, `A4_09`, `A1_01`). The
      # IdeaDiagnosticItemValue rows themselves are created without
      # padding (see DiagnosticInstigator#create_diagnostic_item_values:
      # `"#{idea_id}_#{id}"` → `A2_1`, `A4_9`, …). The former Duke chatbot
      # absorbed the mismatch through Watson NLU; with the wizard we have
      # to align both sides on a single canonical form.
      def normalize_item_value_name(item_value_name)
        item_value_name.to_s.sub(/_0(\d)$/, '_\1')
      end
    end

  end
end
