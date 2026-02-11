// =============================================
// GG_fnc_confirmGuess - Client Only
// Lock in the player's guess and send to server
// =============================================
if (!hasInterface) exitWith {};

if (isNil "GG_guessPos") exitWith {
    diag_log "ArmaGuessr: No guess to confirm";
};

if (GG_confirmed) exitWith {};

// Lock in guess
GG_confirmed = true;

// Remove map click handler (no more changes allowed)
if (!isNil "GG_mapClickEH") then {
    removeMissionEventHandler ["MapSingleClick", GG_mapClickEH];
    GG_mapClickEH = nil;
};

// Remove the confirm button from the map display
private _mapDisplay = findDisplay 12;
if (!isNull _mapDisplay) then {
    private _btn = _mapDisplay displayCtrl 9876;
    if (!isNull _btn) then {
        ctrlDelete _btn;
    };
};

// Update marker to show confirmed
if (GG_guessMarker != "") then {
    GG_guessMarker setMarkerColorLocal "ColorGreen";
    GG_guessMarker setMarkerTextLocal "Guess Confirmed";
};

// Force map open and block closing until results
openMap true;
GG_mapBlockEH = addMissionEventHandler ["EachFrame", {
    if (!visibleMap) then {
        openMap true;
    };
}];

// Send guess to server
[player, GG_guessPos] remoteExecCall ["GG_fnc_receiveGuess", 2];

diag_log format ["ArmaGuessr: Guess confirmed at %1", GG_guessPos];
