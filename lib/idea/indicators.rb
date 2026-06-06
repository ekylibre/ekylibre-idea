# frozen_string_literal: true

require 'yaml'

module Idea
  # Registry of the 53 IDEA4 indicators (A1..A19, B1..B23, C1..C11) and
  # their 450 item_values. Loaded once at boot from config/indicators.yml,
  # which is generated from the IDEA reference spreadsheet
  # (Tableau de référence IDEA_2021_08_17.xlsx).
  class Indicators
    DIMENSIONS = { 'A' => 'Agro-écologique',
                   'B' => 'Socio-territoriale',
                   'C' => 'Économique' }.freeze

    CONFIG_PATH = File.expand_path('../../config/indicators.yml', __dir__)

    # Hand-validated overrides for items whose nature in the YAML was
    # mis-inferred from the (often abbreviated) label. The YAML is the
    # default; these win. Add entries here as Phase 2 reviews each
    # indicator against its IDEA4 PDF spec.
    NATURE_OVERRIDES = {
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
      'A4_17' => 'float',   'A4_20' => 'float',   'A4_21' => 'float',
      # C — autofill items are floats (€/ha), wizard inputs are ranks
      # (integer) or booleans, per the Dimension C IDEA4 spec.
      'C1_1'  => 'float',   'C1_2'  => 'float',   'C1_3'  => 'float',
      'C1_4'  => 'float',   'C1_5'  => 'integer', 'C1_6'  => 'integer',
      'C2_1'  => 'float',   'C2_2'  => 'float',   'C2_3'  => 'float',
      'C3_1'  => 'float',   'C3_2'  => 'float',   'C3_3'  => 'float',
      'C4_1'  => 'integer', 'C4_2'  => 'integer',
      'C5_1'  => 'integer', 'C5_2'  => 'integer', 'C5_3'  => 'boolean',
      'C6_1'  => 'float',   'C6_2'  => 'float',
      'C7_1'  => 'boolean',
      'C8_1'  => 'float',   'C8_2'  => 'float',   'C8_3'  => 'float',
      'C9_1'  => 'integer', 'C9_2'  => 'boolean', 'C9_3'  => 'boolean', 'C9_4' => 'integer',
      'C10_1' => 'float',   'C10_2' => 'float',   'C10_3' => 'float',
      'C10_4' => 'float',   'C10_5' => 'float',
      'C11_1' => 'float',   'C11_2' => 'float',
      # A6-A19 — most items are booleans (practices) or floats (quantities).
      # Hand-validated against the IDEA4 Dimension A (A6-A19) PDF.
      # A6
      'A6_1' => 'boolean', 'A6_2' => 'boolean', 'A6_3' => 'boolean',
      'A6_4' => 'boolean', 'A6_5' => 'float',   'A6_6' => 'float',
      'A6_8' => 'boolean', 'A6_9' => 'float',   'A6_10' => 'float', 'A6_11' => 'float',
      # A7
      'A7_1' => 'float',   'A7_2' => 'float',   'A7_3' => 'float',
      'A7_4' => 'float',   'A7_5' => 'integer',
      # A9
      'A9_1' => 'string',  'A9_2' => 'boolean', 'A9_3' => 'float',
      # A10
      'A10_1' => 'float',  'A10_2' => 'float',  'A10_3' => 'float',
      # A11 — quantities
      'A11_19' => 'float',
      # A12
      'A12_4' => 'boolean', 'A12_5' => 'boolean', 'A12_6' => 'boolean',
      'A12_7' => 'boolean', 'A12_8' => 'boolean', 'A12_9' => 'boolean',
      'A12_10' => 'boolean','A12_11' => 'boolean','A12_12' => 'boolean','A12_13' => 'boolean',
      # A13
      'A13_1' => 'integer', 'A13_2' => 'boolean', 'A13_4' => 'integer',
      'A13_9' => 'boolean',
      # A14
      'A14_1' => 'boolean', 'A14_2' => 'boolean', 'A14_3' => 'integer',
      'A14_4' => 'boolean', 'A14_5' => 'boolean', 'A14_6' => 'boolean',
      # A15
      'A15_1' => 'boolean', 'A15_2' => 'boolean', 'A15_5' => 'boolean',
      # A16-A19 — IFT floats, practices booleans
      'A16_2' => 'float',   'A16_3' => 'float',   'A16_5' => 'float',  'A16_45' => 'float',
      'A16_46' => 'boolean','A16_47' => 'boolean','A16_48' => 'boolean',
      'A17_1' => 'float',   'A17_4' => 'boolean', 'A17_5' => 'boolean',
      'A17_6' => 'boolean', 'A17_7' => 'boolean', 'A17_8' => 'boolean','A17_11' => 'boolean',
      'A18_1' => 'float',   'A18_2' => 'float',   'A18_3' => 'float',
      'A18_19' => 'float',  'A18_20' => 'float',  'A18_21' => 'float','A18_22' => 'float',
      'A19_1' => 'float',   'A19_2' => 'boolean', 'A19_3' => 'boolean',
      'A19_4' => 'boolean', 'A19_5' => 'boolean', 'A19_6' => 'boolean',
      'A19_7' => 'float',   'A19_8' => 'float',   'A19_9' => 'boolean'
    }.merge(
      # Generated bulk first (boolean defaults for B*), then the curated
      # overrides on top. The merge order matters — explicit entries (like
      # B21_1 integer) must win over the bulk default.
      Hash.new.tap do |h|
        %w[B1 B2 B3 B4 B5 B6 B7 B8 B9 B10 B11 B12 B13 B14 B15 B16 B17 B18 B19 B20 B22 B23].each do |ind|
          (1..50).each { |i| h["#{ind}_#{i}"] = 'boolean' }
        end
      end
    ).merge(
      'B21_1' => 'integer'
    ).freeze

    class << self
      # Lazily memoized parsed YAML. Indexed for O(1) lookup.
      def registry
        @registry ||= load_registry
      end

      def reload!
        @registry = nil
        registry
      end

      # @return [Array<Hash>] all 53 indicator descriptors
      def all
        registry[:indicators]
      end

      # @return [Array<String>] indicator ids ordered as in the registry
      def components
        all.map { |i| i[:id] }
      end

      # @return [Array<Hash>] indicators of a given dimension
      def by_dimension(dim)
        all.select { |i| i[:dimension] == dim.to_s }
      end

      # @return [Hash, nil]
      def find(indicator_id)
        registry[:by_id][indicator_id.to_s]
      end

      def label_for(indicator_id)
        find(indicator_id)&.dig(:label)
      end

      def treshold_for(indicator_id)
        find(indicator_id)&.dig(:treshold)
      end

      # Subset of indicators that have at least one item with
      # source: wizard — used to decide whether to render the wizard
      # button on the dashboard. Indicators with no wizard items are
      # autofill-only (rendering a wizard button on them is misleading).
      def scripted_components
        registry[:scripted].dup
      end

      # @return [Boolean]
      def has_questions?(indicator_id)
        registry[:scripted].include?(indicator_id.to_s)
      end

      # Number of items declared for an indicator. Used by
      # DiagnosticInstigator and by the components when looping over
      # placeholders.
      def item_values_count(indicator_id)
        find(indicator_id)&.dig(:items)&.size
      end

      # @return [Array<Hash>] the item descriptors of an indicator
      def items_for(indicator_id)
        find(indicator_id)&.dig(:items) || []
      end

      # Storage nature each item_value expects. Drives the wizard widget
      # choice (number / boolean / string) and the controller's coercion
      # before write.
      def nature_for(item_value_name)
        normalized = normalize_item_value_name(item_value_name)
        NATURE_OVERRIDES[normalized] || registry[:nature_map][normalized] || 'string'
      end

      # Strip the legacy zero-padded numeric suffix that the components
      # emit in `next_indicator` (e.g. `A2_01`, `A4_09`, `A1_01`). The
      # IdeaDiagnosticItemValue rows themselves are created without
      # padding (cf. DiagnosticInstigator#create_diagnostic_item_values).
      def normalize_item_value_name(item_value_name)
        item_value_name.to_s.sub(/_0(\d)$/, '_\1')
      end

      # Used by DiagnosticInstigator. Returns a flat array of
      # IdeaDiagnosticItem attributes hashes, one per indicator.
      def all_item_attributes
        all.map do |ind|
          {
            idea_id: ind[:id],
            name: ind[:label],
            treshold: ind[:treshold],
            group: ind[:dimension]
          }
        end
      end

      # Aggregated score for one dimension (A/B/C) on a given diagnostic.
      # Returns a hash :
      #   {
      #     score: Integer,      # sum of computed indicator scores
      #     max:   Integer,      # sum of indicator tresholds
      #     ratio: Float,        # score / max ∈ [0..1]
      #     percent: Integer,    # ratio × 100, rounded
      #     answered: Integer,   # indicators with a non-nil value
      #     total:    Integer    # indicators in this dimension
      #   }
      # Returns nil-safe values when no indicators are scored yet.
      def dimension_score(diagnostic, dim)
        items = diagnostic.idea_diagnostic_items.select { |it| (it.group || 'A') == dim.to_s }
        max = items.sum { |it| it.treshold.to_i }
        score = items.sum { |it| it.value.to_i }
        answered = items.count { |it| !it.value.nil? }
        ratio = max.positive? ? (score.to_f / max) : 0.0
        {
          score: score,
          max: max,
          ratio: ratio,
          percent: (ratio * 100).round,
          answered: answered,
          total: items.size
        }
      end

      # IDEA4 global score — minimum of the three dimension ratios,
      # rendered on /3 (the historical IDEA scale) and on /100.
      # The IDEA4 reference uses the min so a weak dimension caps the
      # whole sustainability score; using a simple average would let
      # one strong dimension hide problems in another. Refine per the
      # latest IDEA4 spec if/when the formula evolves.
      def global_score(diagnostic)
        per_dim = DIMENSIONS.keys.map { |d| [d, dimension_score(diagnostic, d)] }
        valid = per_dim.select { |_, summary| summary[:max].positive? }
        return { score_3: 0.0, percent: 0, weakest: nil } if valid.empty?

        weakest_code, weakest_summary = valid.min_by { |_, summary| summary[:ratio] }
        ratio = weakest_summary[:ratio]
        {
          score_3: (ratio * 3).round(2),
          percent: (ratio * 100).round,
          weakest: weakest_code
        }
      end

      private

        def load_registry
          raw = YAML.safe_load(File.read(CONFIG_PATH), aliases: false, permitted_classes: [])
          indicators = (raw['indicators'] || []).map { |h| symbolize(h) }
          by_id = indicators.each_with_object({}) { |ind, acc| acc[ind[:id]] = ind }
          scripted = indicators
            .select { |i| (i[:items] || []).any? { |it| it[:source] == 'wizard' } }
            .map { |i| i[:id] }
          nature_map = indicators.flat_map { |i| i[:items] || [] }
            .each_with_object({}) { |it, acc| acc[it[:id]] = it[:nature] }
          {
            indicators: indicators,
            by_id: by_id,
            scripted: scripted,
            nature_map: nature_map
          }
        end

        # Deep symbolize keys so consumers can use `.dig(:items, :id)`.
        def symbolize(obj)
          case obj
          when Hash  then obj.each_with_object({}) { |(k, v), h| h[k.to_sym] = symbolize(v) }
          when Array then obj.map { |v| symbolize(v) }
          else obj
          end
        end
    end
  end
end
