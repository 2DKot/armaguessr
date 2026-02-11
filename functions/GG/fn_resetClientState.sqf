// =============================================
// GG_fnc_resetClientState - Client
// Clean up markers, event handlers between rounds
// =============================================
if (!hasInterface) exitWith {};

diag_log "ArmaGuessr: Resetting client state";

// Remove map click handler
if (!isNil "GG_mapClickEH") then {
    removeMissionEventHandler ["MapSingleClick", GG_mapClickEH];
    GG_mapClickEH = nil;
};

// Remove map block handler
if (GG_mapBlockEH >= 0) then {
    removeMissionEventHandler ["EachFrame", GG_mapBlockEH];
    GG_mapBlockEH = -1;
};

// Delete guess preview marker
if (GG_guessMarker != "") then {
    deleteMarkerLocal GG_guessMarker;
    GG_guessMarker = "";
};

// Delete all result markers
{
    deleteMarkerLocal _x;
} forEach GG_resultMarkers;
GG_resultMarkers = [];

// Reset state
GG_guessPos = nil;
GG_confirmed = false;
GG_showingResults = false;

// Close map
openMap false;
