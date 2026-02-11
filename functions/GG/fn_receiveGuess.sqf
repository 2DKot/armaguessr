// =============================================
// GG_fnc_receiveGuess - Server Only
// Receive and validate a player's guess
// If all players submitted, end round early
// Called with: [_player, _guessPos]
// =============================================
if (!isServer) exitWith {};

params ["_player", "_guessPos"];

// Validate inputs
if (isNull _player) exitWith {
    diag_log "ArmaGuessr: receiveGuess - null player";
};

if (isNil "_guessPos") exitWith {
    diag_log "ArmaGuessr: receiveGuess - nil guess position";
};

private _uid = getPlayerUID _player;
private _name = name _player;

// Check for duplicate submission
if (_uid in GG_submittedPlayers) exitWith {
    diag_log format ["ArmaGuessr: Duplicate guess from %1 (%2) - ignored", _name, _uid];
};

// Record the guess
GG_submittedPlayers pushBack _uid;
GG_allGuesses pushBack [_uid, _name, _guessPos];

diag_log format ["ArmaGuessr: Guess received from %1 (%2) at %3 [%4/%5 players]",
    _name, _uid, _guessPos, count GG_submittedPlayers, count allPlayers];

// Check if all players have submitted - end round early
private _allPlayers = allPlayers - (entities "HeadlessClient_F");
private _allSubmitted = true;

{
    if !((getPlayerUID _x) in GG_submittedPlayers) exitWith {
        _allSubmitted = false;
    };
} forEach _allPlayers;

if (_allSubmitted && count _allPlayers > 0) then {
    diag_log "ArmaGuessr: All players confirmed - ending round early!";
    GG_roundEndTime = serverTime;
    publicVariable "GG_roundEndTime";
};
