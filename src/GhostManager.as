dictionary toggleCache;
dictionary ghostStates;
bool previousEnableGhosts = false;
int previousNumGhosts = 1;
int previousGhostRankOffset = 0;
string lastRecordPid;
int lastOffset = -1;
Json::Value records = Json::Value();

bool wrGhostEnabled = false;

void Update(float dt) {
    if (IsInMap()) return;

    if (g_enableGhosts && !previousEnableGhosts) {
        startnew(EnableAllGhosts);
    } else if (!g_enableGhosts && previousEnableGhosts) {
        startnew(HideAllGhosts);
    }

    if (g_enableGhosts && (g_numGhosts != previousNumGhosts || g_ghostRankOffset != previousGhostRankOffset)) {
        startnew(UpdateVisibleGhosts);
    }

    previousEnableGhosts = g_enableGhosts;
    previousNumGhosts = g_numGhosts;
    previousGhostRankOffset = g_ghostRankOffset;
}

void UpdateVisibleGhosts() {
    HideAllGhosts();
    yield();
    LoadMapRecords();
}

void ToggleLoadedGhosts(array<string> pids) {
    if (GetApp().PlaygroundScript is null) return; // Placeholder for when we can properly whitelist specific gamemodes

    NotifyInfo("Toggling " + pids.Length + " ghosts...");

    for (uint i = 0; i < pids.Length; i++) {
        ToggleGhost(pids[i], false);
    }

    for (uint i = g_ghostRankOffset; i < g_ghostRankOffset + g_numGhosts && i < pids.Length; i++) {
        ToggleGhost(pids[i], true);
    }
}

void ToggleGhost(const string &in playerId, bool enable) {
    // Placeholder for when we can properly whitelist specific gamemodes
    if (GetApp().PlaygroundScript is null) { NotifyWarn("Plugin is currently disabled for all online modes\n (will work on getting a whitelist out for allowed\n online modes). This is to prevent the ability to\n load ghosts in COTD mostly, which some consider to\n be cheating."); return; }

    if (!permissionsOkay) return;

    bool currentState;
    if (ghostStates.Get(playerId, currentState)) {
        if (currentState == enable) {
            return;
        }
    }

    log((enable ? "Toggleing (Enabling)" : "Toggleing (Disabling)") + " ghost for playerId: " + playerId, LogLevel::Info, 58, "ToggleGhost");
    MLHook::Queue_SH_SendCustomEvent(g_MLHookCustomEvent, {playerId});
    ghostStates[playerId] = enable;
}

void EnableAllGhosts() {
    startnew(MapCoro);
    startnew(LoadMapRecords);
}

void HideAllGhosts() {
    array<string> keys = toggleCache.GetKeys();
    for (uint i = 0; i < keys.Length; i++) {
        auto pid = keys[i];
        bool enabled = false;
        toggleCache.Get(pid, enabled);
        if (enabled) {
            ToggleGhost(pid, false);
            toggleCache[pid] = false;
        }
    }
}

UI::InputBlocking OnKeyPress(bool down, VirtualKey key) {
    if (key == g_toggleWrGhostHotkey && down) {
        ToggleWrGhost();
    }
    return UI::InputBlocking::DoNothing;
}

void ToggleWrGhost() {
    if (GetApp().PlaygroundScript is null) return; // Placeholder for when we can properly whitelist specific gamemodes

    wrGhostEnabled = !wrGhostEnabled;
    NotifyInfo((wrGhostEnabled ? "Enabling" : "Disabling") + " WR ghost...");
    ToggleGhost(GetOffsetGhostId(), wrGhostEnabled);
}

string GetOffsetGhostId() {
    array<string> pids = UpdateMapRecords();
    if (pids.Length > 0) {
        return pids[0];
    }
    return "";
}