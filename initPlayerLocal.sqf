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
GG_urgencyPP = -1;

// Disable damage for this player (no dying in this mode)
player allowDamage false;

// Disable all communication channels to prevent marker placement
for "_i" from 0 to 5 do {
    _i enableChannel false;
};

// HUD: show round timer (pauses during results phase)
// Also handles urgency effects (beep + red vignette) when timer < 10s
[] spawn {
    waitUntil {!isNil "GG_roundEndTime"};

    // Create post-process effect for red vignette
    GG_urgencyPP = ppEffectCreate ["ColorCorrections", 1500];
    GG_urgencyPP ppEffectEnable true;
    GG_urgencyPP ppEffectAdjust [1, 1, 0, [0,0,0,0], [1,1,1,1], [0,0,0,0]];
    GG_urgencyPP ppEffectCommit 0;

    private _lastBeepTime = -1;

    while {!GG_missionEnded} do {
        private _timeLeft = GG_roundEndTime - serverTime;
        if (_timeLeft < 0) then { _timeLeft = 0; };

        if (!GG_showingResults) then {
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

            // Urgency effects when timer < 10s and player hasn't confirmed
            if (_timeLeft <= 10 && _timeLeft > 0 && !GG_confirmed) then {
                private _currentSec = floor _timeLeft;

                // Beep once per second
                if (_currentSec != _lastBeepTime) then {
                    _lastBeepTime = _currentSec;
                    playSound "hint";

                    // Red flash pulse - intensity increases as time decreases
                    private _intensity = 0.15 + (1 - (_timeLeft / 10)) * 0.2;
                    GG_urgencyPP ppEffectAdjust [1, 1, 0, [1,0,0,_intensity], [1,0.9,0.9,1], [0,0,0,0]];
                    GG_urgencyPP ppEffectCommit 0;

                    // Fade out the flash
                    [] spawn {
                        sleep 0.3;
                        if (!isNil "GG_urgencyPP") then {
                            GG_urgencyPP ppEffectAdjust [1, 1, 0, [0,0,0,0], [1,1,1,1], [0,0,0,0]];
                            GG_urgencyPP ppEffectCommit 0.4;
                        };
                    };
                };
            } else {
                // Clear any lingering effect
                if (_lastBeepTime != -1 && (GG_confirmed || _timeLeft > 10)) then {
                    _lastBeepTime = -1;
                    GG_urgencyPP ppEffectAdjust [1, 1, 0, [0,0,0,0], [1,1,1,1], [0,0,0,0]];
                    GG_urgencyPP ppEffectCommit 0;
                };
            };
        } else {
            // During results, clear effects
            if (_lastBeepTime != -1) then {
                _lastBeepTime = -1;
                GG_urgencyPP ppEffectAdjust [1, 1, 0, [0,0,0,0], [1,1,1,1], [0,0,0,0]];
                GG_urgencyPP ppEffectCommit 0;
            };
        };
        sleep 0.1;
    };

    // Cleanup
    GG_urgencyPP ppEffectEnable false;
    ppEffectDestroy GG_urgencyPP;
    hintSilent "";
};
