# ArmaGuessr -- Multiplayer Navigation Mode (Arma 3)

## Goal

Create a fully multiplayer-compatible Arma 3 mission where:

-   Server selects a hidden random position each round.
-   Players are teleported to that position and explore the terrain on foot.
-   Players open the map, click to place a guess.
-   Players must press **Confirm** to submit.
-   After confirmation:
    -   Map remains forced open.
    -   Guess cannot be changed.
-   When timer ends:
    -   All player guesses are revealed on the map.
    -   Distances to the real position are calculated (server-side only).
    -   Results are displayed on the map via markers.
-   Multiple rounds supported.
-   Accumulated scoring across rounds.
-   Final scores shown via setDebriefingText at mission end.

The mission must be Workshop-ready and secure (server authoritative).

------------------------------------------------------------------------

# 1. Architecture

Mission folder structure:

```
armaguessr.Altis/
├── description.ext
├── initServer.sqf
├── initPlayerLocal.sqf
│
├── functions/
│   └── GG/
│       ├── fn_startRound.sqf
│       ├── fn_prepareClient.sqf
│       ├── fn_confirmGuess.sqf
│       ├── fn_receiveGuess.sqf
│       ├── fn_endRound.sqf
│       ├── fn_showResults.sqf
│       ├── fn_resetClientState.sqf
│       └── fn_showFinalScores.sqf
│
└── task.md  (this file)
```

All logic must be inside functions via CfgFunctions.
Function prefix: `GG` (namespace `GG_fnc_*`).

------------------------------------------------------------------------

# 2. Multiplayer Rules

-   Server is authoritative.
-   Clients never calculate distance.
-   Clients never know real position until reveal.
-   All guesses validated server-side.
-   Prevent duplicate submissions.
-   Works on any map (uses worldSize for random position generation).

------------------------------------------------------------------------

# 3. Player Setup

-   All players on **BLUFOR** side.
-   No weapons at all.
-   Equipment: compass and binoculars only.
-   Players move on foot only (no vehicles).
-   Player slots are placed manually in Eden editor (mission.sqm not generated).

------------------------------------------------------------------------

# 4. Round Flow

## On Server (initServer.sqf)

-   Initialize:
    -   `GG_roundNumber = 0`
    -   `GG_totalRounds = 5` (from lobby param)
    -   `GG_roundDuration = 120` (from lobby param)
    -   `GG_totalScores = createHashMap`
-   Call `GG_fnc_startRound`

------------------------------------------------------------------------

## fn_startRound.sqf (Server Only)

1.  Increment round number.
2.  Reset `GG_allGuesses = []`
3.  Generate random position on land using `BIS_fnc_randomPos` + land check.
4.  Set:
    -   `GG_roundPos` (server only, NOT publicVariable'd)
    -   `GG_roundEndTime = serverTime + GG_roundDuration`
5.  PublicVariable `GG_roundEndTime` only (NOT `GG_roundPos`).
6.  RemoteExec `GG_fnc_prepareClient` to all clients with round position
    (players need it for teleport).
7.  Wait until `GG_roundEndTime`.
8.  Call `GG_fnc_endRound`.

------------------------------------------------------------------------

# 5. Client Guess Phase

## fn_prepareClient.sqf (Client)

-   Teleport player to the round position.
-   Remove all weapons/items, give compass + binoculars.
-   Reset:
    -   `GG_guessPos = nil`
    -   `GG_confirmed = false`
-   Add `onMapSingleClick` handler.
-   Show hint with round number and timer info.
-   Add Confirm button via `addAction` on the player.

------------------------------------------------------------------------

## onMapSingleClick behavior

If not confirmed:
-   Store `_pos` as `GG_guessPos`.
-   Create/move local preview marker.
-   Confirm button becomes usable.

------------------------------------------------------------------------

# 6. Confirm Logic

## fn_confirmGuess.sqf (Client)

-   If `GG_guessPos` is nil -> exit.
-   Set `GG_confirmed = true`.
-   Disable further map clicks (`onMapSingleClick ""`).
-   Force map open (block closing).
-   RemoteExecCall to server: `[player, GG_guessPos] remoteExecCall ["GG_fnc_receiveGuess", 2]`

------------------------------------------------------------------------

# 7. Server Guess Handling

## fn_receiveGuess.sqf (Server)

1.  Validate server execution.
2.  Ensure player has not already submitted.
3.  Mark player as submitted.
4.  Push guess data into `GG_allGuesses`.

------------------------------------------------------------------------

# 8. End Round

## fn_endRound.sqf (Server)

1.  Calculate `distance2D` for each guess vs `GG_roundPos`.
2.  Build results array `[distance, uid, name, guessPos]`.
3.  Sort ascending by distance.
4.  Apply scoring formula: `score = max(0, 5000 - (distance / 5))`
5.  Update cumulative scores in `GG_totalScores`.
6.  Build results data and real position.
7.  RemoteExec `GG_fnc_showResults` to all clients.
8.  Wait 10 seconds (results display time).
9.  If more rounds remain: call `GG_fnc_startRound`.
10. If final round: call `GG_fnc_showFinalScores`.

------------------------------------------------------------------------

# 9. Results Reveal (Client)

## fn_showResults.sqf

1.  Force open map.
2.  Create green marker for real position.
3.  Create red markers for each player's guess.
4.  Draw line markers from each guess to real position.
5.  Color top 3 differently (gold, silver, bronze).
6.  Show hint with round rankings (Rank, Name, Distance, Round Score).

------------------------------------------------------------------------

# 10. Final Scores

## fn_showFinalScores.sqf (Server)

1.  Sort players by total accumulated score (descending).
2.  Build formatted text with `<br/>` line breaks.
3.  Format: `"1. PlayerName - 12345 pts | best: 50m<br/>"` etc.
4.  Call: `["End1", ["ArmaGuessr - Final Scores", _text]] remoteExec ["setDebriefingText", 0, true]`
5.  Call: `"End1" call BIS_fnc_endMission`

------------------------------------------------------------------------

# 11. UI Requirements

## During Round

-   Hint showing round number and time remaining.
-   addAction "Confirm Guess" on player (or via map UI).
-   Local marker for guess preview.

## Results Phase

-   Map markers: green (real pos), red (guesses), lines connecting them.
-   Top 3 markers in gold/silver/bronze.
-   Hint with rankings table.

## End of Mission

-   setDebriefingText with final accumulated scores.

------------------------------------------------------------------------

# 12. Anti-Abuse Measures

-   Ignore duplicate submissions.
-   Server calculates distances (never client).
-   Reset submission state each round.
-   Clear all markers between rounds.
-   Force map open after confirm (prevent closing).
-   Round position sent to clients only for teleport; scoring uses server-side copy.

------------------------------------------------------------------------

# 13. Mission Parameters (Lobby)

Via `class Params` in description.ext:

| Parameter       | Default | Options              |
| --------------- | ------- | -------------------- |
| Round duration  | 120     | 60, 90, 120, 180, 240 |
| Number of rounds| 5       | 3, 5, 7, 10          |

------------------------------------------------------------------------

# 14. Defaults

-   Round duration: 120 seconds
-   Number of rounds: 5
-   Results display time: 10 seconds between rounds
-   Scoring: `max(0, 5000 - (distance / 5))`

------------------------------------------------------------------------

# 15. Technical Patterns (from reference missions)

-   `CfgFunctions` with tag `GG`, file path `functions\GG`, files named `fn_*.sqf`
-   `isServer` / `hasInterface` guards
-   `missionNamespace setVariable [key, value, true]` for JIP-safe public state
-   `remoteExec` / `remoteExecCall` for client-server communication
-   `publicVariable` for broadcasting simple values
-   `setDebriefingText` + `BIS_fnc_endMission` for end screen
-   `onMapSingleClick` for map click handling
-   `openMap true` to force map open
-   Markers via `createMarkerLocal` for client-only markers

------------------------------------------------------------------------

# 16. Workshop Quality Checklist

-   Clean RPT (no script errors).
-   Multiplayer tested.
-   No hardcoded player references on server.
-   Proper tags (Multiplayer, Competitive, Minigame).
-   Works on any map (no map-specific logic).

------------------------------------------------------------------------

# Final Requirement

Produce a fully working, server-authoritative multiplayer mission
expandable to multiple maps. Player slots are placed in Eden editor.
