// =============================================
// GG_fnc_showFinalScores - Server Only
// Build final scoreboard and end mission via setDebriefingText
// =============================================
if (!isServer) exitWith {};

diag_log "ArmaGuessr: Building final scores";

GG_missionEnded = true;
publicVariable "GG_missionEnded";

// Convert hashmap to array for sorting
private _scoresArray = [];
{
    private _uid = _x;
    private _data = GG_totalScores get _uid;
    _data params ["_name", "_totalScore", "_bestDist"];
    _scoresArray pushBack [_totalScore, _name, _bestDist, _uid];
} forEach keys GG_totalScores;

// Sort descending by total score
_scoresArray sort false;

// Build formatted text
private _text = "";
{
    _x params ["_totalScore", "_name", "_bestDist", "_uid"];

    private _rank = _forEachIndex + 1;
    private _bestText = if (_bestDist < 99999) then {format ["%1m", round _bestDist]} else {"N/A"};

    _text = _text + format ["%1. %2 — %3 pts | best: %4<br/>",
        _rank, _name, _totalScore, _bestText];
} forEach _scoresArray;

if (_text == "") then {
    _text = "No players scored.<br/>";
};

_text = _text + "<br/>Thanks for playing ArmaGuessr!";

diag_log format ["ArmaGuessr: Final scores text: %1", _text];

// Set debriefing and end mission
["End1", ["ArmaGuessr - Final Scores", _text]] remoteExec ["setDebriefingText", 0, true];

// Brief delay to ensure debriefing text propagates to clients
sleep 0.5;

"End1" remoteExec ["BIS_fnc_endMission", 0, true];
