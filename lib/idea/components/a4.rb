module Idea
  module Components
    class A4 < Base
      INDICATOR = 'A4'
      RESCUE_VALUE = nil

      def initialize(diagnostic_id: nil)
        super(diagnostic_id: diagnostic_id, idea_name: INDICATOR)
      end

      # What should Duke ask to the user for this component
      # @returns [DukeResponse] : response
      def duke_redirect
        return Duke::DukeResponse.new if @idea_diagnostic.nil?

        if item('A4_10').value.nil?
          Duke::DukeResponse.new(
            redirect: 'A4_10',
            sentence: duke_information_tag(I18n.t('idea.confirm_fallow_land_1', fallow_area: fallow_area)) + I18n.t('idea.confirm_fallow_land_2'),
            parsed: @idea_diagnostic.id,
            options: fallow_area
          )
        elsif item('A4_9').value.nil? && gardening?
          Duke::DukeResponse.new(
            redirect: 'A4_09',
            parsed: @idea_diagnostic.id
          )
        else
          Duke::DukeResponse.new
        end
      end

      # Check if score is calculable & updates it if so
      def update_global_score
        @idea_diagnostic_item.update!(value: compute_score) if computable?
      end

      #  Resets IdeaDiagnosticItem value & IdeaDiagnosticItemValues values
      def reset_indicator
        @idea_diagnostic_item.update!(value: nil)
        reset_item_values(INDICATOR)
      end

      # A4_1 calculator value
      # Surfaces des îlots de cultures supérieurs à 12 ha 
      def a4_1
        begin
          aps = ActivityProduction.of_campaign(@campaign).where(usage: %w[grain fodder meadow silage hay straw plant seed], support_nature: 'cultivation').where(size_value: 12..500)
          if aps.present?
            aps.pluck(:size_value).compact.sum.round(2).to_f
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4_2 calculator value
      # Surface totale en grandes cultures et cultures fourragères
      def a4_2
        begin
          aps = ActivityProduction.of_campaign(@campaign).where(usage: %w[grain fodder meadow silage hay straw plant seed], support_nature: 'cultivation')
          if aps.present?
            aps.pluck(:size_value).compact.sum.round(2).to_f
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      # Surfaces des îlots de cultures supérieurs à 6 ha | Arboriculture
      def a4_3
        begin
          if arboricultural_idea?
            aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('arboricultural_idea').varieties).where(size_value: 6..500)
            if aps.present?
              aps.pluck(:size_value).compact.sum.round(2).to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      # Surfaces des îlots de cultures supérieurs à 6 ha | Viticulture
      def a4_4
        begin
          if vineyard_idea?
            aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('vineyard_idea').varieties).where(size_value: 6..500)
            if aps.present?
              aps.pluck(:size_value).compact.sum.round(2).to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      # Surfaces des îlots de cultures supérieurs à 6 ha | Maraichage
      def a4_5
        begin
          if gardening?
            aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('sheltered_gardening_idea').varieties).where(size_value: 6..500)
            if aps.present?
              aps.pluck(:size_value).compact.sum.round(2).to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      # Surface totale en Arboriculture
      def a4_6
        begin
          if arboricultural_idea?
            aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('arboricultural_idea').varieties)
            if aps.present?
              aps.pluck(:size_value).compact.sum.round(2).to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      # Surface totale en Viticulture
      def a4_7
        begin
          if vineyard_idea?
            aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('vineyard_idea').varieties)
            if aps.present?
              aps.pluck(:size_value).compact.sum.round(2).to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      # Surface totale en Maraichage
      def a4_8
        begin
          if gardening?
            aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('sheltered_gardening_idea').varieties)
            if aps.present?
              aps.pluck(:size_value).compact.sum.round(2).to_f
            else
              0.0
            end
          else
            0.0
          end
        rescue
          RESCUE_VALUE
        end
      end

      # A4 calculator value
      def a4_11
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_12
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_13
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_14
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_15
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_16
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_17
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_18
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_19
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_20
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_21
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_22
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_23
        # TODO: do it correctly
        1
      end

       # A4_24 calculator value is build during A1_10

       # A4 calculator value
       def a4_25
        # TODO: do it correctly
        1
      end

       # A4 calculator value
       def a4_26
        # TODO: do it correctly
        1
      end

      private

        # Item 1.1 : Grandes cultures, cultures fourragères et cultures légumières
        def item_1_1_score
          sgic = (item('A4_1').value / item('A4_2').value).round(2) * 100 if item('A4_2').value > 0.0
          if sgic.present?
            if sgic == 0.0
              3
            elsif (sgic > 0.0 && sgic <= 15.0)
              2
            elsif (sgic > 15.0 && sgic <= 30.0)
              1
            elsif (sgic > 30.0)
              0
            end
          else
            nil
          end
        end

        # Item 1.2 : Arboriculture
        def item_1_2_score
          if arboricultural_idea?
            sgic = (item('A4_3').value / item('A4_6').value).round(2) * 100 if item('A4_6').value > 0.0
            if sgic.present?
              if sgic == 0.0
                3
              elsif (sgic > 0.0 && sgic <= 15.0)
                2
              elsif (sgic > 15.0 && sgic <= 30.0)
                1
              elsif (sgic > 30.0)
                0
              end
            else
              nil
            end
          else
            RESCUE_VALUE
          end
        end

        # Item 1.3 : Viticulture
        def item_1_3_score
          if vineyard_idea?
            sgic = (item('A4_4').value / item('A4_7').value).round(2) * 100 if item('A4_7').value > 0.0
            if sgic.present?
              if sgic == 0.0
                3
              elsif (sgic > 0.0 && sgic <= 15.0)
                2
              elsif (sgic > 15.0 && sgic <= 30.0)
                1
              elsif (sgic > 30.0)
                0
              end
            else
              nil
            end
          else
            RESCUE_VALUE
          end
        end

        # Item 1.4 : Maraichage
        def item_1_4_score
          total = 0.0
          if gardening?
            sgic = (item('A4_5').value / item('A4_8').value).round(2) * 100 if item('A4_8').value > 0.0
            if sgic.present?
              if sgic == 0.0
                total += 2.0
              elsif (sgic > 0.0 && sgic <= 30.0)
                total += 1.0
              elsif (sgic > 30.0)
                total += 0.0
              end
            else
              nil
            end
            if item('A4_9').value.present? && item('A4_9').value == true
              total += 1.0
            end
            total
          else
            RESCUE_VALUE
          end
        end

        # Item 1.5 : STH
        def item_1_5_score
          if sth.present?
            if sth > 0.0
              3
            else
              0
            end
          else
            RESCUE_VALUE
          end
        end

        # Item 1 Compute
        def item_1
          sum = 0.0
          divider = 0.0
          if item_1_1_score.present?
            sum += (item_1_1_score * item('A4_2').value)
            divider += item('A4_2').value
          end
          if item_1_2_score.present?
            sum += (item_1_2_score * item('A4_6').value)
            divider += item('A4_6').value
          end
          if item_1_3_score.present?
            sum += (item_1_3_score * item('A4_7').value)
            divider += item('A4_7').value
          end
          if item_1_4_score.present?
            sum += (item_1_4_score * item('A4_8').value)
            divider += item('A4_8').value
          end
          if item_1_5_score.present?
            sum += (item_1_5_score * sth)
            divider += sth
          end
          (sum / divider).round(2).to_f
        end

        # Item 2 Compute
        def item_2
          0.0
        end

        # Calculate IdeaDiagnosticItem global score
        def compute_score
          item_1 + item_2
        end

        def computable?
          true
        end

    end
  end
end
