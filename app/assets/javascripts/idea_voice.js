// Voice input for the Idea wizard.
//
// Two backends, transparent to the rest of the wizard — both insert
// transcribed text into the active input/textarea inside the modal,
// letting the user review/edit before submitting:
//
//   1. Web Speech API (in-browser, streaming interim results, free) —
//      used whenever the browser exposes it. The audio never leaves the
//      device.
//   2. MediaRecorder + POST to Duke's `/api/v1/stt/transcribe` — server-
//      side Whisper, used when Web Speech is missing AND `stt_server_enabled`
//      is true. Audio is sent only after the user stops recording (no
//      streaming).
//
// Pattern lifted from ekylibre/app/javascript/duke/widget.js (lines
// 221-403) and trimmed to the dictation-only contract: no NLU, no
// WebSocket, no Duke message protocol.

(function () {
  'use strict';

  var STT_CONFIG_URL = '/backend/idea_diagnostics/stt_config';

  function getSpeechRecognitionCtor() {
    return window.SpeechRecognition || window.webkitSpeechRecognition || null;
  }

  function hasMediaRecorder() {
    return typeof window.MediaRecorder !== 'undefined' && !!navigator.mediaDevices;
  }

  function pickWebmMimeType() {
    if (typeof MediaRecorder === 'undefined') return 'audio/webm';
    var candidates = ['audio/webm;codecs=opus', 'audio/webm', 'audio/ogg;codecs=opus'];
    for (var i = 0; i < candidates.length; i += 1) {
      if (MediaRecorder.isTypeSupported(candidates[i])) return candidates[i];
    }
    return '';
  }

  function IdeaVoice(modalEl) {
    this.modal = modalEl;
    this.voiceSlot = modalEl.querySelector('[data-role="voice"]');
    this.micButton = modalEl.querySelector('[data-role="mic"]');
    this.inputSlot = modalEl.querySelector('[data-role="input"]');

    this.config = null;            // populated lazily on first mic click
    this.configRequested = false;
    this.recognition = null;       // active SpeechRecognition instance
    this.recognizing = false;
    this.mediaRecorder = null;
    this.mediaStream = null;
    this.mediaChunks = [];
    this.committedTranscript = '';

    var self = this;
    this.micButton.addEventListener('click', function () { self.toggle(); });

    // Reveal the mic immediately when Web Speech is available. The
    // server-STT path requires a config fetch first; we defer that
    // until the user clicks (saves a roundtrip on every page load).
    if (getSpeechRecognitionCtor()) {
      this.showButton();
    }
  }

  IdeaVoice.prototype.showButton = function () {
    if (this.voiceSlot) this.voiceSlot.hidden = false;
  };

  // First click that finds Web Speech absent triggers a config fetch.
  // If the fetch confirms server STT is on, we keep the button revealed
  // and the next click starts recording; otherwise we hide the button
  // and leave the user with the textarea only.
  IdeaVoice.prototype.ensureConfigOrFallback = function () {
    var self = this;
    if (this.config || this.configRequested) {
      return Promise.resolve(this.config);
    }
    this.configRequested = true;
    return fetch(STT_CONFIG_URL, {
      credentials: 'same-origin',
      headers: { Accept: 'application/json' }
    })
      .then(function (resp) {
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        return resp.json();
      })
      .then(function (cfg) {
        self.config = cfg;
        if (cfg.stt_server_enabled && cfg.stt_url && hasMediaRecorder()) {
          self.showButton();
        } else if (!getSpeechRecognitionCtor()) {
          // Neither path available — hide the button.
          if (self.voiceSlot) self.voiceSlot.hidden = true;
        }
        return cfg;
      })
      .catch(function () { return null; });
  };

  IdeaVoice.prototype.toggle = function () {
    if (this.recognizing) {
      if (this.recognition) {
        this.recognition.stop();
      } else if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
        this.mediaRecorder.stop();
      }
      return;
    }

    if (getSpeechRecognitionCtor()) {
      this.startWebSpeech();
      return;
    }

    var self = this;
    this.ensureConfigOrFallback().then(function (cfg) {
      if (cfg && cfg.stt_server_enabled && cfg.stt_url && hasMediaRecorder()) {
        self.startServerRecording();
      }
      // else: silently noop. The button has been hidden by ensureConfigOrFallback.
    });
  };

  // --- Web Speech path (no audio leaves the device) ---

  IdeaVoice.prototype.startWebSpeech = function () {
    var Ctor = getSpeechRecognitionCtor();
    var recognition = new Ctor();
    recognition.lang = 'fr-FR';
    recognition.interimResults = true;
    recognition.continuous = false;
    recognition.maxAlternatives = 1;

    var input = this.activeInput();
    this.committedTranscript = input && input.value ? input.value.replace(/\s+$/, '') + ' ' : '';

    var self = this;
    recognition.onstart = function () {
      self.recognizing = true;
      self.micButton.classList.add('idea-wizard__mic--recording');
    };

    recognition.onresult = function (event) {
      var interim = '';
      for (var i = event.resultIndex; i < event.results.length; i += 1) {
        var result = event.results[i];
        var transcript = (result[0] && result[0].transcript) || '';
        if (result.isFinal) {
          self.committedTranscript += transcript;
        } else {
          interim += transcript;
        }
      }
      var target = self.activeInput();
      if (target) {
        target.value = (self.committedTranscript + interim).replace(/^\s+/, '');
      }
    };

    recognition.onerror = function (/* event */) {
      // 'aborted' is user-initiated stop, not an error worth surfacing.
      // Other errors are intentionally silent — the textarea remains
      // available and the user has a clear visual signal (mic was red,
      // now isn't) that voice failed.
    };

    recognition.onend = function () {
      self.recognizing = false;
      self.recognition = null;
      self.micButton.classList.remove('idea-wizard__mic--recording');
      var target = self.activeInput();
      if (target && target.focus) {
        try { target.focus(); } catch (e) { /* hidden */ }
      }
    };

    this.recognition = recognition;
    try {
      recognition.start();
    } catch (e) {
      // Calling start() on an already-running instance throws.
      this.recognition = null;
    }
  };

  // --- Server-STT path (audio POSTed to Duke /api/v1/stt/transcribe) ---

  IdeaVoice.prototype.startServerRecording = function () {
    if (!this.config || !this.config.stt_url || !this.config.auth) return;

    var self = this;
    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(function (stream) {
        var mimeType = pickWebmMimeType();
        var recorder;
        try {
          recorder = mimeType ? new MediaRecorder(stream, { mimeType: mimeType }) : new MediaRecorder(stream);
        } catch (e) {
          stream.getTracks().forEach(function (t) { t.stop(); });
          return;
        }

        self.mediaStream = stream;
        self.mediaRecorder = recorder;
        self.mediaChunks = [];

        recorder.ondataavailable = function (e) {
          if (e.data && e.data.size > 0) self.mediaChunks.push(e.data);
        };

        recorder.onstop = function () {
          var tracks = (self.mediaStream && self.mediaStream.getTracks()) || [];
          tracks.forEach(function (t) { t.stop(); });
          self.mediaStream = null;
          var chunks = self.mediaChunks;
          self.mediaChunks = [];
          self.mediaRecorder = null;
          self.recognizing = false;
          self.micButton.classList.remove('idea-wizard__mic--recording');

          var blobType = recorder.mimeType || mimeType || 'audio/webm';
          var blob = new Blob(chunks, { type: blobType });
          if (blob.size === 0) return;
          self.uploadAudio(blob);
        };

        self.recognizing = true;
        self.micButton.classList.add('idea-wizard__mic--recording');
        try {
          recorder.start();
        } catch (e) {
          stream.getTracks().forEach(function (t) { t.stop(); });
          self.mediaStream = null;
          self.mediaRecorder = null;
          self.recognizing = false;
          self.micButton.classList.remove('idea-wizard__mic--recording');
        }
      })
      .catch(function () { /* permission denied or no device — silent */ });
  };

  IdeaVoice.prototype.uploadAudio = function (blob) {
    var auth = this.config.auth;
    var form = new FormData();
    var ext = blob.type.indexOf('ogg') !== -1 ? 'ogg' : 'webm';
    form.append('audio', blob, 'clip.' + ext);

    var self = this;
    fetch(this.config.stt_url, {
      method: 'POST',
      headers: {
        Authorization: 'simple-token ' + auth.email + ' ' + auth.token,
        'X-Tenant': auth.tenant
      },
      body: form
    })
      .then(function (resp) {
        if (!resp.ok) throw new Error('HTTP ' + resp.status);
        return resp.json();
      })
      .then(function (data) {
        var text = (data && data.text ? String(data.text) : '').trim();
        if (!text) return;
        var input = self.activeInput();
        if (!input) return;
        var prefix = input.value ? input.value.replace(/\s+$/, '') + ' ' : '';
        input.value = (prefix + text).replace(/^\s+/, '');
        if (input.focus) {
          try { input.focus(); } catch (e) { /* hidden */ }
        }
      })
      .catch(function () { /* silent — user can retry or type */ });
  };

  // Returns the textarea or input the wizard is currently presenting.
  // The wizard rebuilds the input slot on every renderQuestion, so we
  // resolve it lazily per voice action rather than caching it once.
  IdeaVoice.prototype.activeInput = function () {
    return this.inputSlot.querySelector('textarea, input[type="text"], input[type="number"]');
  };

  // --- Boot ---
  function boot() {
    var modal = document.getElementById('idea-question-modal');
    if (!modal) return;
    if (modal.dataset.ideaVoiceBound === '1') return;
    modal.dataset.ideaVoiceBound = '1';
    new IdeaVoice(modal);
  }

  document.addEventListener('DOMContentLoaded', boot);
  document.addEventListener('turbolinks:load', boot);
})();
