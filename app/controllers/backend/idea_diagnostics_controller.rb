# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2015 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
module Backend
  class IdeaDiagnosticsController < Backend::BaseController
    # Whitelist gating the user-supplied `indicator` param before it is
    # used to resolve a constant under Idea::Components::*. Without this
    # the next_question/answer actions would be a const_get arbitrary-class hole.
    # Source of truth is the YAML registry (53 indicators), so we don't
    # have to hand-maintain a list every time a new indicator lands.
    NEXT_QUESTION_INDICATORS = Idea::Indicators.components.freeze

    # Valid natures for IdeaDiagnosticItemValue#set! — mirrors the
    # model-side inclusion validator. Bouncing here gives a JSON 422
    # before the model raises RecordInvalid with a less actionable error.
    ANSWER_NATURES = %w[boolean integer float string].freeze

    manage_restfully
    before_action :notify_rotations, only: :new

    unroll

    list(order: { name: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :code, url: true
      t.column :auditor, label: :auditor
      t.column :state, label_method: 'state.tl'
      t.column :created_at
      t.column :stopped_at
    end

    def index
      @label = :new_diagnostic.tl
    end

    def create
      @idea_diagnostic = resource_model.new(permitted_params)
      if save_and_redirect(
        @idea_diagnostic,
        url: (params[:create_and_continue] ? { action: :new, continue: true } : (params[:redirect] || { action: :show, id: 'id'.c })),
        notify: :idea_record_created.tl,
        identifier: :name
      )
        Idea::DiagnosticInstigator.new(@idea_diagnostic).instigate
        return
      end
      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    def reset_indicator
      unless NEXT_QUESTION_INDICATORS.include?(params[:indicator])
        return render(json: { error: 'invalid_indicator' }, status: :unprocessable_entity)
      end

      component = Idea::Components.const_get(params[:indicator]).new(diagnostic_id: params[:diagnostic_id])
      component.reset_indicator
      IdeaAutofillJob.perform_later(params[:diagnostic_id], indicator: params[:indicator])
    end

    # Returns the next question the wizard should ask for a given
    # indicator on a given diagnostic, or { terminal: true } when the
    # questionnaire is exhausted. JSON-only; the wizard polls this on
    # every turn.
    def next_question
      unless NEXT_QUESTION_INDICATORS.include?(params[:indicator])
        return render(json: { error: 'invalid_indicator' }, status: :unprocessable_entity)
      end

      diagnostic = IdeaDiagnostic.find_by(id: params[:id])
      return render(json: { error: 'not_found' }, status: :not_found) unless diagnostic

      render(json: question_for(params[:indicator], diagnostic).as_json)
    end

    # Voice input config consumed by idea_voice.js. Returns the
    # current session's auth + the URL of Duke's Whisper transcription
    # endpoint when DUKE_STT_SERVER_ENABLED is on. When the server-side
    # STT is off, `stt_url` is null and the wizard falls back to the
    # browser's Web Speech API only. Mirrors the contract of
    # Backend::DukeWidgetController#show so the plugin can be tested
    # without depending on the main repo's widget controller.
    def stt_config
      return render(json: { error: 'unauthorized' }, status: :unauthorized) unless current_user

      render json: {
        stt_server_enabled: stt_server_enabled?,
        stt_url: stt_server_enabled? ? duke_stt_url : nil,
        auth: {
          email: current_user.email,
          token: current_user.authentication_token,
          tenant: Apartment::Tenant.current
        }
      }
    end

    # Persists the user's answer for one item_value, recomputes any
    # affected indicator score, and returns the next question to ask.
    # Expected JSON payload:
    #   { "indicator": "A1", "item_value": "A1_10", "value": "18", "nature": "integer" }
    # `nature` is optional and defaults to "string" — the wizard front-end
    # should send it explicitly when the input is numeric or boolean.
    def answer
      unless NEXT_QUESTION_INDICATORS.include?(params[:indicator])
        return render(json: { error: 'invalid_indicator' }, status: :unprocessable_entity)
      end

      diagnostic = IdeaDiagnostic.find_by(id: params[:id])
      return render(json: { error: 'not_found' }, status: :not_found) unless diagnostic

      # Defensive normalization — `enrich()` already emits canonical names
      # to the wizard, but older clients (Turbolinks-cached pages) may
      # still POST padded names like 'A2_01'. Strip the padding to match
      # the IdeaDiagnosticItemValue.name column.
      item_value_name = Idea::Indicators.normalize_item_value_name(params[:item_value])

      # Scoping the item_value lookup through the diagnostic prevents a
      # caller from writing into another diagnostic's item_values by
      # supplying a foreign `item_value` name.
      item_value = IdeaDiagnosticItemValue
        .joins(:idea_diagnostic_item)
        .where(idea_diagnostic_items: { idea_diagnostic_id: diagnostic.id })
        .find_by(name: item_value_name)
      unless item_value
        return render(json: { error: 'item_value_not_found' }, status: :unprocessable_entity)
      end

      # Indicators.nature_for is authoritative — it mirrors what
      # compute_score expects. We accept the client's `nature` only as a
      # hint for the `string` default; the mapped nature always wins for
      # named item_values to guarantee compute_score's arithmetic.
      nature = Idea::Indicators.nature_for(item_value_name)
      if nature == 'string' && ANSWER_NATURES.include?(params[:nature].to_s)
        nature = params[:nature]
      end

      item_value.set!(coerce_answer(params[:value], nature), nature)

      # A2's questionnaire can write into A1_* item_values (cross-indicator
      # flow, see Phase 1.2 mapping). Recompute the score of both the
      # current indicator and the one the item_value belongs to so the
      # dashboard updates without the user having to re-click.
      #
      # Score recompute can fail on partial data (legacy item_values
      # stored in the wrong column before NATURE_MAP, autofill that hasn't
      # populated a divisor, etc.). The user's answer is already persisted
      # at this point — a score-recompute crash shouldn't drop the round-
      # trip. Log and continue; the dashboard will reflect the stale score
      # until the next successful recompute.
      indicators_to_score = Set.new([params[:indicator]])
      # Extract the indicator prefix correctly: "A10_3" → "A10", "C11_2" →
      # "C11", "B23_15" → "B23". A naive [0, 2] would yield "A1" for
      # "A10_3" and recompute the wrong indicator.
      if (m = params[:item_value].to_s.match(/\A([ABC]\d+)_\d+\z/))
        owning = m[1]
        indicators_to_score << owning if NEXT_QUESTION_INDICATORS.include?(owning)
      end
      indicators_to_score.each do |ind|
        begin
          Idea::Components.const_get(ind).new(diagnostic_id: diagnostic.id).update_global_score
        rescue StandardError => e
          Rails.logger.warn("[idea] update_global_score(#{ind}) failed on diagnostic ##{diagnostic.id}: #{e.class}: #{e.message}")
        end
      end

      render(json: question_for(params[:indicator], diagnostic).as_json)
    end

    def update
      return unless @idea_diagnostic = find_and_check(:idea_diagnostic)

      t3e(@idea_diagnostic.attributes)
      @idea_diagnostic.attributes = permitted_params
      return if save_and_redirect(@idea_diagnostic, url: params[:redirect] || { action: :show, id: 'id'.c },
notify: :idea_record_updated.tl, identifier: :name)

      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    private

      def permitted_params
        params.require(:idea_diagnostic).permit!
      end

      def notify_rotations
        notify_warning(:notify_rotations.tl)
      end

      def question_for(indicator, diagnostic)
        question = Idea::Components.const_get(indicator).new(diagnostic_id: diagnostic.id).next_question
        enrich(question)
      end

      # Layer two server-side enrichments on top of what the component
      # built:
      #   * sentence — backfilled from i18n (`idea.questions.<indicator>`)
      #     for the ~15 questions whose static prompt used to live in the
      #     former Duke chatbot's Watson skill;
      #   * nature  — looked up in Idea::Indicators::NATURE_MAP so the
      #     wizard JS renders the right widget (number / radio / textarea)
      #     and the answer endpoint coerces the value into the matching
      #     column (integer_value / float_value / …) before downstream
      #     compute_score does arithmetic on it.
      def enrich(question)
        return question if question.terminal?
        # Canonical form aligns the wizard payload with the
        # IdeaDiagnosticItemValue row names ('A2_01' → 'A2_1', etc.).
        # i18n lookup keeps the padded key (matches what's in
        # config/locales/.../action.yml under idea.questions.<key>).
        normalized = Idea::Indicators.normalize_item_value_name(question.next_indicator)
        Idea::Question.new(
          next_indicator: normalized,
          sentence: question.sentence.presence || I18n.t("idea.questions.#{question.next_indicator}", default: nil),
          prefilled_value: question.prefilled_value,
          diagnostic_id: question.diagnostic_id,
          nature: question.nature || Idea::Indicators.nature_for(normalized)
        )
      end

      def coerce_answer(raw, nature)
        case nature
        when 'integer' then raw.to_i
        when 'float'   then raw.to_f
        when 'boolean' then ActiveModel::Type::Boolean.new.cast(raw)
        else                raw.to_s
        end
      end

      # Mirrors Backend::DukeWidgetController#duke_ws_url + duke_stt_url:
      # falls back to the WS URL with scheme swapped if DUKE_HTTP_URL is
      # unset, so a single env (DUKE_WS_URL) covers the common dev case.
      def duke_stt_url
        base = ENV.fetch('DUKE_HTTP_URL') do
          ws = ENV.fetch('DUKE_WS_URL', 'ws://localhost:8000/ws')
          ws.sub(%r{\Aws://}, 'http://').sub(%r{\Awss://}, 'https://').sub(%r{/ws\z}, '')
        end
        "#{base}/api/v1/stt/transcribe"
      end

      def stt_server_enabled?
        ActiveModel::Type::Boolean.new.cast(ENV['DUKE_STT_SERVER_ENABLED']) == true
      end

  end
end
