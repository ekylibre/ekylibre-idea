// Idea questionnaire wizard.
//
// Listens for clicks on `.idea_duke` buttons (rendered by show.html.haml),
// opens the modal declared in _question_modal.html.haml, and drives the
// question/answer loop against the REST endpoints introduced in Phases 3.1/3.2:
//
//   GET  /backend/idea_diagnostics/:id/next_question?indicator=A1
//   POST /backend/idea_diagnostics/:id/answer
//
// Vanilla JS — jQuery is only used to trigger Bootstrap's modal lifecycle
// (already required by the Ekylibre main repo). No new dependency.
//
// Voice input is bolted on by idea_voice.js in Phase 3b.

(function () {
  'use strict';

  var MODAL_ID = 'idea-question-modal';

  function csrfToken() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  }

  // The server-side enrich() pass attaches `nature` from
  // Idea::Indicators::NATURE_MAP to every question. We fall back to a
  // type sniff on prefilled_value only if the server omitted nature
  // (defensive — should not happen in practice).
  function pickNature(question) {
    if (question.nature) return question.nature;
    var pf = question.prefilled_value;
    if (typeof pf === 'boolean') return 'boolean';
    if (typeof pf === 'number') return Number.isInteger(pf) ? 'integer' : 'float';
    return 'string';
  }

  function IdeaWizard(modalEl) {
    this.modal = modalEl;
    this.wizard = modalEl.querySelector('[data-role="wizard"]');
    this.titleEl = modalEl.querySelector('[data-role="indicator-title"]');
    this.sentenceEl = modalEl.querySelector('[data-role="sentence"]');
    this.prefilledEl = modalEl.querySelector('[data-role="prefilled"]');
    this.prefilledValueEl = modalEl.querySelector('[data-role="prefilled-value"]');
    this.inputEl = modalEl.querySelector('[data-role="input"]');
    this.errorEl = modalEl.querySelector('[data-role="error"]');
    this.submitEl = modalEl.querySelector('[data-role="submit"]');
    this.cancelEl = modalEl.querySelector('[data-role="cancel"]');

    this.diagnosticId = null;
    this.indicator = null;
    this.currentQuestion = null;
    this.busy = false;

    var self = this;
    this.submitEl.addEventListener('click', function () { self.submitAnswer(); });
    this.cancelEl.addEventListener('click', function () { self.cancel(); });
  }

  IdeaWizard.prototype.open = function (diagnosticId, indicator) {
    this.diagnosticId = diagnosticId;
    this.indicator = indicator;
    this.currentQuestion = null;
    this.clearError();
    this.resetInput();
    this.titleEl.textContent = indicator;
    this.sentenceEl.innerHTML = '';
    this.show();
    this.fetchNext();
  };

  IdeaWizard.prototype.show = function () {
    if (window.jQuery) {
      window.jQuery('#' + MODAL_ID).modal('show');
    } else {
      this.modal.style.display = 'block';
    }
  };

  IdeaWizard.prototype.hide = function () {
    if (window.jQuery) {
      window.jQuery('#' + MODAL_ID).modal('hide');
    } else {
      this.modal.style.display = 'none';
    }
  };

  // Cancel — user-initiated dismissal. Close without reloading; nothing
  // was persisted past the last successful POST, so the dashboard already
  // reflects the latest state on its next refresh.
  IdeaWizard.prototype.cancel = function () {
    this.hide();
  };

  // Reached when the server signals `terminal: true`. Reload the page so
  // the score cells and progress bars in show.html.haml pick up the new
  // values written by update_global_score during the last POST.
  IdeaWizard.prototype.finish = function () {
    this.hide();
    window.location.reload();
  };

  IdeaWizard.prototype.fetchNext = function () {
    var self = this;
    this.setBusy(true);
    var url = '/backend/idea_diagnostics/' + encodeURIComponent(this.diagnosticId) +
      '/next_question?indicator=' + encodeURIComponent(this.indicator);
    return fetch(url, {
      credentials: 'same-origin',
      headers: { 'Accept': 'application/json' }
    })
      .then(function (resp) {
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        return resp.json();
      })
      .then(function (question) { self.renderQuestion(question); })
      .catch(function (e) {
        if (window.console && console.error) console.error('[idea_wizard]', e);
        self.showError('Erreur réseau. Réessayez.');
      })
      .then(function () { self.setBusy(false); });
  };

  IdeaWizard.prototype.submitAnswer = function () {
    if (this.busy || !this.currentQuestion) return;
    var read = this.readValue();
    if (read.value === '' || read.value === null) {
      this.showError('Réponse manquante.');
      return;
    }
    this.clearError();
    this.setBusy(true);

    var body = new FormData();
    body.append('indicator', this.indicator);
    body.append('item_value', this.currentQuestion.next_indicator);
    body.append('value', String(read.value));
    body.append('nature', read.nature);

    var self = this;
    var url = '/backend/idea_diagnostics/' + encodeURIComponent(this.diagnosticId) + '/answer';
    return fetch(url, {
      method: 'POST',
      credentials: 'same-origin',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      },
      body: body
    })
      .then(function (resp) {
        if (resp.ok) {
          return resp.json().then(function (q) { self.renderQuestion(q); });
        }
        return resp.json().catch(function () { return {}; }).then(function (err) {
          self.showError(err && err.error ? 'Erreur : ' + err.error : 'Erreur HTTP ' + resp.status + '.');
        });
      })
      .catch(function (e) {
        if (window.console && console.error) console.error('[idea_wizard]', e);
        self.showError('Erreur réseau. Réessayez.');
      })
      .then(function () { self.setBusy(false); });
  };

  IdeaWizard.prototype.renderQuestion = function (question) {
    if (!question || question.terminal) {
      this.finish();
      return;
    }
    this.currentQuestion = question;

    this.titleEl.textContent = this.indicator + ' — ' + question.next_indicator;
    // `sentence` is HTML generated by Idea::SentenceHelpers#idea_information_tag
    // + I18n.t — both server-trusted; no user input flows here, so
    // innerHTML is safe.
    this.sentenceEl.innerHTML = question.sentence || '';

    var prefilled = question.prefilled_value;
    if (prefilled !== null && prefilled !== undefined && prefilled !== '') {
      this.prefilledValueEl.textContent = prefilled;
      this.prefilledEl.classList.remove('hidden');
    } else {
      this.prefilledEl.classList.add('hidden');
    }

    this.renderInput(question);
  };

  IdeaWizard.prototype.renderInput = function (question) {
    var nature = pickNature(question);
    var prefilledValue = question.prefilled_value;
    this.inputEl.innerHTML = '';
    this.inputEl.dataset.nature = nature;

    var el;
    if (nature === 'boolean') {
      el = this.buildBooleanInput();
    } else if (nature === 'integer' || nature === 'float') {
      el = this.buildNumberInput(nature === 'integer' ? '1' : 'any', prefilledValue);
    } else {
      el = this.buildTextInput();
    }
    this.inputEl.appendChild(el);

    // Focus the first input for keyboard ergonomics.
    var firstFocusable = el.querySelector ? (el.querySelector('input, textarea') || el) : el;
    if (firstFocusable && firstFocusable.focus) {
      try { firstFocusable.focus(); } catch (e) { /* JSDOM / hidden */ }
    }
  };

  IdeaWizard.prototype.buildBooleanInput = function () {
    var wrapper = document.createElement('div');
    wrapper.className = 'idea-wizard__bool-options';
    var yes = document.createElement('label');
    yes.innerHTML = '<input type="radio" name="idea-answer" value="true"> Oui';
    var no = document.createElement('label');
    no.innerHTML = '<input type="radio" name="idea-answer" value="false"> Non';
    wrapper.appendChild(yes);
    wrapper.appendChild(no);
    return wrapper;
  };

  IdeaWizard.prototype.buildNumberInput = function (step, prefilled) {
    var input = document.createElement('input');
    input.type = 'number';
    input.step = step;
    input.name = 'idea-answer';
    input.className = 'form-control';
    if (prefilled !== null && prefilled !== undefined && prefilled !== '') {
      input.value = prefilled;
    }
    return input;
  };

  IdeaWizard.prototype.buildTextInput = function () {
    var textarea = document.createElement('textarea');
    textarea.rows = 2;
    textarea.name = 'idea-answer';
    textarea.className = 'form-control';
    return textarea;
  };

  IdeaWizard.prototype.resetInput = function () {
    this.inputEl.innerHTML = '';
    this.prefilledEl.classList.add('hidden');
  };

  IdeaWizard.prototype.readValue = function () {
    var nature = this.inputEl.dataset.nature || 'string';
    if (nature === 'boolean') {
      var checked = this.inputEl.querySelector('input[name="idea-answer"]:checked');
      return { value: checked ? checked.value : '', nature: nature };
    }
    var el = this.inputEl.querySelector('input, textarea');
    return { value: el ? el.value : '', nature: nature };
  };

  IdeaWizard.prototype.showError = function (msg) {
    this.errorEl.textContent = msg;
    this.errorEl.classList.remove('hidden');
  };

  IdeaWizard.prototype.clearError = function () {
    this.errorEl.textContent = '';
    this.errorEl.classList.add('hidden');
  };

  IdeaWizard.prototype.setBusy = function (busy) {
    this.busy = busy;
    this.submitEl.disabled = busy;
  };

  // --- Boot ---
  //
  // Turbolinks navigates without firing DOMContentLoaded on subsequent
  // page visits, so we bind to both events. Re-binding is guarded by a
  // dataset flag so the click listener isn't attached twice when the
  // same DOM persists across navigations.
  function boot() {
    var modal = document.getElementById(MODAL_ID);
    if (!modal) return;
    if (modal.dataset.ideaWizardBound === '1') return;
    modal.dataset.ideaWizardBound = '1';

    var wizard = new IdeaWizard(modal);
    // Expose for idea_voice.js (Phase 3b) and for manual debugging.
    window.IdeaWizardInstance = wizard;

    document.addEventListener('click', function (e) {
      var trigger = e.target.closest ? e.target.closest('.idea_duke') : null;
      if (!trigger) return;
      e.preventDefault();
      var diagId = trigger.dataset.diagnosticId;
      var indicator = trigger.dataset.indicator;
      if (!diagId || !indicator) return;
      wizard.open(diagId, indicator);
    });

    // .idea_restart — the "reset / restart" arrow on each indicator row.
    // POSTs to the existing /reset_idea_indicator endpoint (controller
    // wipes the indicator's item_values and re-enqueues the autofill
    // job), then reloads so the dashboard reflects the cleared state.
    // The handler used to live in the now-removed duke_integration.js;
    // re-attaching it here keeps the row controls functional.
    document.addEventListener('click', function (e) {
      var trigger = e.target.closest ? e.target.closest('.idea_restart') : null;
      if (!trigger) return;
      e.preventDefault();
      var diagId = trigger.dataset.diagnosticId;
      var indicator = trigger.dataset.indicator;
      if (!diagId || !indicator) return;

      var body = new FormData();
      body.append('diagnostic_id', diagId);
      body.append('indicator', indicator);

      fetch('/reset_idea_indicator', {
        method: 'POST',
        credentials: 'same-origin',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken()
        },
        body: body
      })
        .then(function (resp) {
          if (resp.ok) window.location.reload();
        })
        .catch(function (err) {
          if (window.console && console.error) console.error('[idea_restart]', err);
        });
    });
  }

  document.addEventListener('DOMContentLoaded', boot);
  document.addEventListener('turbolinks:load', boot);
})();
