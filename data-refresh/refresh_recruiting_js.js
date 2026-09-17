/**
 * Refresh Recruiting Data — Dropdown Button
 * --------------------------------------------
 * Triggers incremental or full REST data refresh
 * (requisitions, candidates, applications) via pkg_rest_recruiting.
 *
 * APEX setup:
 *   - Upload as Static Application File, reference on page 24:
 *       JS File URL:  #APP_FILES#refresh_recruiting_js#MIN#.js
 *   - Requires Ajax callback: REFRESH_RECRUITING
 *   - Called from a menu button: refreshRecruiting('INCREMENTAL')
 *     or refreshRecruiting('FULL')
 */
(function () {
    "use strict";

    window.refreshRecruiting = function (mode) {
        var label = (mode === "FULL") ? "Full refresh" : "Sync";
        var msg = label + " recruiting data (requisitions, candidates, applications)?";
        if (mode === "FULL") {
            msg += "\n\nNote: Full refresh may take up to 5 minutes.";
        }
        apex.message.confirm(msg,
            function (ok) {
                if (!ok) return;

                apex.message.clearErrors();
                var lSpinner$ = apex.util.showSpinner();

                apex.server.process("REFRESH_RECRUITING", {
                    x01: mode
                }, {
                    dataType: "json",
                    timeout: 600000,
                    success: function (data) {
                        lSpinner$.remove();
                        if (data.status === "OK") {
                            apex.message.showPageSuccess(
                                (data.mode === "FULL" ? "Full refresh" : "Sync")
                                + " complete: "
                                + data.requisitions + " requisitions, "
                                + data.candidates + " candidates, "
                                + data.applications + " applications"
                            );
                            apex.region("applicant_irr").refresh();
                        } else {
                            apex.message.showErrors([{
                                type: "error",
                                location: "page",
                                message: data.message
                            }]);
                        }
                    },
                    error: function (jqXHR, textStatus, errorThrown) {
                        lSpinner$.remove();
                        apex.message.showErrors([{
                            type: "error",
                            location: "page",
                            message: "Request failed: " + errorThrown
                        }]);
                    }
                });
            }
        );
    };

})();
