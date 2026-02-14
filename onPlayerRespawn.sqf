// =============================================
// ArmaGuessr - Player Respawn Handler
// Safety net: teleport back to round position if someone somehow dies
// =============================================
params ["_newUnit", "_oldUnit"];

diag_log "ArmaGuessr: Player respawned - re-preparing client";

// Re-disable damage immediately
_newUnit allowDamage false;

// Re-prepare the client for the current round if one is active
if (!isNil "GG_roundPos" && !GG_missionEnded) then {
    [GG_roundPos, GG_roundNumber] call GG_fnc_prepareClient;
};
