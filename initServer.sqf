// =============================================
// ArmaGuessr - Server Initialization
// =============================================
diag_log "ArmaGuessr: Server initializing...";

// Read lobby parameters
GG_roundDuration = ["RoundDuration", 120] call BIS_fnc_getParamValue;
GG_totalRounds   = ["TotalRounds", 5] call BIS_fnc_getParamValue;

// Initialize state
GG_roundNumber  = 0;
GG_totalScores  = createHashMap; // key = UID, value = [name, totalScore, bestDistance]
GG_allGuesses   = [];
GG_missionEnded = false;

// Broadcast config to clients
publicVariable "GG_roundDuration";
publicVariable "GG_totalRounds";
publicVariable "GG_missionEnded";

// Countdown before first round with visual feedback
[] spawn {
    for "_i" from 5 to 1 step -1 do {
        private _msg = format ["ArmaGuessr\n\nGame starting in %1...", _i];
        [_msg] remoteExec ["hintSilent", 0];
        sleep 1;
    };
    diag_log "ArmaGuessr: Starting first round...";
    [] call GG_fnc_startRound;
};
