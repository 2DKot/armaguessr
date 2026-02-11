// =============================================
// GG_fnc_prepareClient - Client Only
// Teleport player, reset state, set up map click + confirm button
// Called with: [_roundPos, _roundNumber]
// =============================================
if (!hasInterface) exitWith {};

params ["_roundPos", "_roundNumber"];

diag_log format ["ArmaGuessr: Preparing client for round %1", _roundNumber];

// Clean up previous round state
[] call GG_fnc_resetClientState;

// Reset guess state
GG_guessPos = nil;
GG_confirmed = false;

// Teleport player to round position
player setPos _roundPos;

// Remove all gear and give compass + binoculars
removeAllWeapons player;
removeAllItems player;
removeAllAssignedItems player;
removeBackpack player;
removeVest player;
removeHeadgear player;
removeGoggles player;

// Add required items
player linkItem "ItemMap";
player linkItem "ItemCompass";
player addWeapon "Binocular";

// Disable damage
player allowDamage false;

// Set up map click handler
GG_mapClickEH = addMissionEventHandler ["MapSingleClick", {
    params ["_units", "_pos", "_alt", "_shift"];

    if (GG_confirmed) exitWith {};

    // Store guess position
    GG_guessPos = _pos;

    // Create or move preview marker
    if (GG_guessMarker != "") then {
        deleteMarkerLocal GG_guessMarker;
    };

    GG_guessMarker = createMarkerLocal ["GG_myGuess", _pos];
    GG_guessMarker setMarkerTypeLocal "hd_dot";
    GG_guessMarker setMarkerColorLocal "ColorRed";
    GG_guessMarker setMarkerTextLocal "My Guess";
}];

// Spawn loop to show Confirm button on map display
[] spawn {
    while {!GG_confirmed && !GG_missionEnded} do {
        sleep 0.3;

        // Only show button when map is open, guess is placed, and not yet confirmed
        if (visibleMap && !isNil "GG_guessPos" && !GG_confirmed) then {
            private _mapDisplay = findDisplay 12;
            if (!isNull _mapDisplay && isNull (_mapDisplay displayCtrl 9876)) then {
                private _btn = _mapDisplay ctrlCreate ["RscButton", 9876];
                _btn ctrlSetPosition [
                    safeZoneX + safeZoneW * 0.40,
                    safeZoneY + safeZoneH * 0.93,
                    safeZoneW * 0.20,
                    safeZoneH * 0.05
                ];
                _btn ctrlSetText "CONFIRM GUESS";
                _btn ctrlCommit 0;
                _btn ctrlAddEventHandler ["ButtonClick", {
                    [] call GG_fnc_confirmGuess;
                }];
            };
        };
    };
};

// Auto-submit guess when timer runs out (fallback if player doesn't confirm)
[] spawn {
    waitUntil {sleep 0.5; serverTime >= GG_roundEndTime || GG_missionEnded || GG_confirmed};

    if (!GG_confirmed && !GG_missionEnded) then {
        // Remove confirm button from map
        private _mapDisplay = findDisplay 12;
        if (!isNull _mapDisplay) then {
            private _btn = _mapDisplay displayCtrl 9876;
            if (!isNull _btn) then { ctrlDelete _btn; };
        };

        if (!isNil "GG_guessPos") then {
            [player, GG_guessPos] remoteExecCall ["GG_fnc_receiveGuess", 2];
            diag_log format ["ArmaGuessr: Auto-submitted guess at %1", GG_guessPos];
        } else {
            diag_log "ArmaGuessr: Round ended with no guess placed";
        };
        GG_confirmed = true;
    };
};

// Starting hint
hintSilent format [
    "ArmaGuessr\n\nRound %1 / %2\nTime: %3s\n\nExplore the area!\nOpen map (M) and click to place your guess.\nConfirm when ready - round ends early if all confirm.",
    _roundNumber,
    GG_totalRounds,
    floor GG_roundDuration
];
