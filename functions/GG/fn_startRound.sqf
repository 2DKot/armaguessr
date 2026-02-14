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

// Clean up vehicles and objects from previous round
if (!isNil "GG_spawnedQuads") then {
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach GG_spawnedQuads;
};
GG_spawnedQuads = [];

if (!isNil "GG_spawnedObjects") then {
    { if (!isNull _x) then { deleteVehicle _x; }; } forEach GG_spawnedObjects;
};
GG_spawnedObjects = [];

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

// Spawn colored smoke at the round position so players can find their way back
private _smoke = "SmokeShellGreen" createVehicle _pos;
if (isNil "GG_spawnedObjects") then { GG_spawnedObjects = []; };
GG_spawnedObjects pushBack _smoke;

// Respawn smoke periodically (smoke grenades expire after ~45s)
private _smokePos = +_pos;
[_smokePos] spawn {
    params ["_smokePos"];
    while {serverTime < GG_roundEndTime && !GG_missionEnded} do {
        sleep 40;
        if (serverTime < GG_roundEndTime && !GG_missionEnded) then {
            private _newSmoke = "SmokeShellGreen" createVehicle _smokePos;
            GG_spawnedObjects pushBack _newSmoke;
        };
    };
};

// Spawn quad bikes if enabled
if (GG_quadBikes == 1) then {
    private _players = allPlayers - (entities "HeadlessClient_F");
    {
        private _dir = (_forEachIndex / (count _players max 1)) * 360;
        private _dist = 3 + random 3;
        private _spawnPos = [
            (_pos select 0) + (sin _dir) * _dist,
            (_pos select 1) + (cos _dir) * _dist,
            0
        ];

        private _quad = "B_Quadbike_01_F" createVehicle _spawnPos;
        _quad setDir (random 360);
        _quad allowDamage false;
        GG_spawnedQuads pushBack _quad;

        diag_log format ["ArmaGuessr: Spawned quad bike at %1 for %2", _spawnPos, name _x];
    } forEach _players;
};

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
