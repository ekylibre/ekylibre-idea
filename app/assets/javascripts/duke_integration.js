//= require action_cable
(function (D, $) {

    $(document).on('click', '.idea_duke', function() { // On idea-edit btn-click
      intent = 'IDEA_' + this.dataset.indicator
      D.webchat.new_active_session(intent, this.dataset.diagnosticId)
    });

    $(document).on('click', '.idea_restart', function() { // On idea-edit btn-click
      $.ajax('/reset_idea_indicator', {
        type: 'post',
        dataType: 'json',
        data: {
          diagnostic_id: this.dataset.diagnosticId,
          indicator: this.dataset.indicator
        },
        success: ((data) => {window.location.reload();})
      });
    });
  

})(window.Duke = window.Duke || {}, jQuery);