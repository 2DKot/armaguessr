// =============================================
// GG_fnc_endRound - Server Only
// Calculate scores, build results, broadcast
// =============================================
if (!isServer) exitWith {};

diag_log format ["ArmaGuessr: Ending round %1 - %2 guesses received", GG_roundNumber, count GG_allGuesses];

private _realPos = GG_roundPos;
private _results = [];

// Calculate distances and scores for each guess
{
    _x params ["_uid", "_name", "_guessPos"];

    private _distance = _realPos distance2D _guessPos;
    private _roundScore = 0 max (5000 - (_distance / 5));
    _roundScore = round _roundScore;

    // Update cumulative scores
    private _existing = GG_totalScores getOrDefault [_uid, [_name, 0, 99999]];
    _existing params ["_eName", "_eTotalScore", "_eBestDist"];

    private _newTotal = _eTotalScore + _roundScore;
    private _newBest = _eBestDist min _distance;

    GG_totalScores set [_uid, [_name, _newTotal, _newBest]];

    _results pushBack [_distance, _uid, _name, _guessPos, _roundScore, _newTotal];

    diag_log format ["ArmaGuessr: %1 - distance: %2m, round score: %3, total: %4",
        _name, round _distance, _roundScore, _newTotal];
} forEach GG_allGuesses;

// Also handle players who didn't guess (score 0 for this round)
{
    private _uid = getPlayerUID _x;
    private _playerName = name _x;
    if !(_uid in GG_submittedPlayers) then {
        // Ensure they exist in totalScores
        private _existing = GG_totalScores getOrDefault [_uid, [_playerName, 0, 99999]];
        // They get 0 points this round, add to results
        _results pushBack [99999, _uid, _playerName, [0,0,0], 0, _existing select 1];
        diag_log format ["ArmaGuessr: %1 - no guess submitted", _playerName];
    };
} forEach allPlayers;

// Sort by distance ascending (closest first)
_results sort true;

// Broadcast results to clients
[_results, _realPos, GG_roundNumber] remoteExec ["GG_fnc_showResults", 0, true];

// Wait for results display, then continue
[] spawn {
    if (GG_roundNumber >= GG_totalRounds) then {
        // Final round - show results briefly then go straight to debriefing
        sleep 10;
        diag_log "ArmaGuessr: All rounds complete, showing final scores";
        [] call GG_fnc_showFinalScores;
    } else {
        // More rounds - show results for 10 seconds
        sleep 10;
        diag_log format ["ArmaGuessr: Starting next round (%1/%2)", GG_roundNumber + 1, GG_totalRounds];
        [] call GG_fnc_startRound;
    };
};
