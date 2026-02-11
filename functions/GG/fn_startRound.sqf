// =============================================
// GG_fnc_startRound - Server Only
// Starts a new round: pick position, broadcast to clients
// =============================================
if (!isServer) exitWith {};

// Increment round
GG_roundNumber = GG_roundNumber + 1;
publicVariable "GG_roundNumber";
diag_log format ["ArmaGuessr: Starting round %1 / %2", GG_roundNumber, GG_totalRounds];

// Reset guesses
GG_allGuesses = [];
GG_submittedPlayers = [];

// Generate random position on land
private _worldSize = worldSize;
private _pos = [0,0,0];
private _attempts = 0;
private _found = false;

while {!_found && _attempts < 500} do {
    _pos = [random _worldSize, random _worldSize, 0];

    // Check it's on land and not in water
    if (!surfaceIsWater _pos) then {
        // Check it's not too close to edge (100m buffer)
        if ((_pos select 0) > 100 && (_pos select 0) < (_worldSize - 100) &&
            (_pos select 1) > 100 && (_pos select 1) < (_worldSize - 100)) then {
            _found = true;
        };
    };
    _attempts = _attempts + 1;
};

if (!_found) then {
    // Fallback: center of map
    _pos = [_worldSize / 2, _worldSize / 2, 0];
    diag_log "ArmaGuessr: WARNING - Could not find suitable land position, using map center";
};

// Snap to ground
_pos set [2, 0];
GG_roundPos = _pos;
diag_log format ["ArmaGuessr: Round %1 position: %2", GG_roundNumber, GG_roundPos];

// Set timer
GG_roundEndTime = serverTime + GG_roundDuration;
publicVariable "GG_roundEndTime";

// Tell all clients to prepare (send them the position for teleport)
[GG_roundPos, GG_roundNumber] remoteExec ["GG_fnc_prepareClient", 0, true];

// Wait for round to end
[] spawn {
    waitUntil {sleep 1; serverTime >= GG_roundEndTime || GG_missionEnded};

    if (!GG_missionEnded) then {
        // Grace period: wait 2 seconds for auto-submitted guesses to arrive over network
        diag_log format ["ArmaGuessr: Round %1 timer up - waiting for late guesses...", GG_roundNumber];
        sleep 2;
        diag_log format ["ArmaGuessr: Round %1 ended - processing %2 guesses", GG_roundNumber, count GG_allGuesses];
        [] call GG_fnc_endRound;
    };
};
