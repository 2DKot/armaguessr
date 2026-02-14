// =============================================
// GG_fnc_showResults - Client
// Display round results on map with markers
// Called with: [_results, _realPos, _roundNumber]
// _results: array of [distance, uid, name, guessPos, roundScore, totalScore]
// =============================================
if (!hasInterface) exitWith {};

params ["_results", "_realPos", "_roundNumber"];

diag_log format ["ArmaGuessr: Showing results for round %1", _roundNumber];

// Clean up previous state
[] call GG_fnc_resetClientState;

// Pause the HUD timer loop (AFTER reset, since reset clears this flag)
GG_showingResults = true;

// Force open map
openMap true;

// Block map closing during results
GG_mapBlockEH = addMissionEventHandler ["EachFrame", {
    if (!visibleMap) then {
        openMap true;
    };
}];

// Create marker for real position
private _realMarker = createMarkerLocal ["GG_realPos", _realPos];
_realMarker setMarkerTypeLocal "mil_objective";
_realMarker setMarkerColorLocal "ColorGreen";
_realMarker setMarkerTextLocal "Real Position";
_realMarker setMarkerSizeLocal [1.2, 1.2];
GG_resultMarkers pushBack _realMarker;

private _medals = ["[1st]", "[2nd]", "[3rd]"];

// Build hint text
private _hintText = format ["--- Round %1 Results ---\n\n", _roundNumber];

// Create markers for each guess
{
    _x params ["_distance", "_uid", "_name", "_guessPos", "_roundScore", "_totalScore"];

    private _rank = _forEachIndex + 1;

    // Skip players who didn't guess (distance 99999) from map markers
    if (_distance < 99999) then {
        // Guess marker
        private _markerName = format ["GG_guess_%1", _uid];
        private _marker = createMarkerLocal [_markerName, _guessPos];
        _marker setMarkerTypeLocal "hd_dot";
        _marker setMarkerTextLocal format ["%1 (%2m)", _name, round _distance];
        GG_resultMarkers pushBack _marker;

        _marker setMarkerColorLocal "ColorYellow";

        // Line from guess to real position (marker centered at midpoint)
        private _lineName = format ["GG_line_%1", _uid];
        private _midPoint = [
            ((_guessPos select 0) + (_realPos select 0)) / 2,
            ((_guessPos select 1) + (_realPos select 1)) / 2
        ];
        private _lineMarker = createMarkerLocal [_lineName, _midPoint];
        _lineMarker setMarkerShapeLocal "RECTANGLE";
        private _dist = _guessPos distance2D _realPos;
        private _dir = _guessPos getDir _realPos;
        _lineMarker setMarkerSizeLocal [10, _dist / 2];
        _lineMarker setMarkerDirLocal _dir;
        _lineMarker setMarkerBrushLocal "SolidFull";
        GG_resultMarkers pushBack _lineMarker;

        _lineMarker setMarkerColorLocal "ColorYellow";
        _lineMarker setMarkerAlphaLocal 0.4;
    };

    // Hint text
    private _medal = if (_forEachIndex < 3) then {_medals select _forEachIndex} else {""};
    private _distText = if (_distance < 99999) then {format ["%1m", round _distance]} else {"No guess"};
    _hintText = _hintText + format ["%1. %2 %3 - %4 (+%5 pts) [Total: %6]\n",
        _rank, _medal, _name, _distText, _roundScore, _totalScore];

} forEach _results;

// Show results with countdown
GG_resultsText = _hintText;
private _isFinalRound = _roundNumber >= (missionNamespace getVariable ["GG_totalRounds", 5]);
GG_isFinalRound = _isFinalRound;
[] spawn {
    for "_i" from 10 to 1 step -1 do {
        if (GG_isFinalRound) then {
            hintSilent format ["%1\nFinal scores in %2s...", GG_resultsText, _i];
        } else {
            hintSilent format ["%1\nNext round in %2s...", GG_resultsText, _i];
        };
        sleep 1;
    };
};
