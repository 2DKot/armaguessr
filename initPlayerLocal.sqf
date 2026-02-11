// =============================================
// ArmaGuessr - Client Initialization
// =============================================
diag_log "ArmaGuessr: Client initializing...";

// Local state
GG_guessPos   = nil;
GG_confirmed  = false;
GG_guessMarker = "";
GG_resultMarkers = [];
GG_mapBlockEH = -1;
GG_showingResults = false;

// Disable damage for this player (no dying in this mode)
player allowDamage false;

// HUD: show round timer (pauses during results phase)
[] spawn {
    waitUntil {!isNil "GG_roundEndTime"};

    while {!GG_missionEnded} do {
        if (!GG_showingResults) then {
            private _timeLeft = GG_roundEndTime - serverTime;
            if (_timeLeft < 0) then { _timeLeft = 0; };
            private _roundNum = missionNamespace getVariable ["GG_roundNumber", 0];
            private _totalRnds = missionNamespace getVariable ["GG_totalRounds", 5];

            hintSilent format [
                "ArmaGuessr\n\nRound %1 / %2\nTime: %3s\n\n%4",
                _roundNum,
                _totalRnds,
                floor _timeLeft,
                if (GG_confirmed) then {"Guess submitted - waiting for results..."} else {
                    if (!isNil "GG_guessPos") then {"Open map and click CONFIRM GUESS"} else {"Open map (M) and click to guess"}
                }
            ];
        };
        sleep 0.5;
    };
    hintSilent "";
};
