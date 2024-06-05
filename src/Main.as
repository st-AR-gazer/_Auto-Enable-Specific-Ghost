NadeoApi@ api;

void Main() {
    PermsCheck();
    if (!permissionsOkay) return;

    FetchManifest();

    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
    startnew(MapCoro);
}

string s_currMap = "";
bool previousEnableGhosts = false;
int previousNumGhosts = 1;
int previousGhostRankOffset = 0;
bool mapRecordsLoaded = false;

dictionary toggleCache;
dictionary ghostStates;

void MapCoro() {
    while(true) {
        sleep(273);
        if (!g_enableGhosts) continue;
        if (s_currMap != CurrentMap) {
            s_currMap = CurrentMap;
            log("Map changed to: " + s_currMap, LogLevel::Info, 29, "MapCoro");
            ResetToggleCache();
            log("Reset toggle cache", LogLevel::Info, 31, "MapCoro");
            LoadMapRecords();
            log("Loaded map records", LogLevel::Info, 33, "MapCoro");
            mapRecordsLoaded = true;
        }
    }
}

void ResetToggleCache() {
    toggleCache.DeleteAll();
    ghostStates.DeleteAll();
    records = Json::Value();
    lastRecordPid = "";
    mapRecordsLoaded = false;
}

CTrackMania@ get_app() {
    return cast<CTrackMania>(GetApp());
}

CGameManiaAppPlayground@ get_cmap() {
    auto app = get_app();
    if (app is null) return null;
    return app.Network.ClientManiaAppPlayground;
}

string get_CurrentMap() {
    auto app = get_app();
    if (app is null) return "";
    auto map = app.RootMap;
    if (map is null) return "";
    return map.MapInfo.MapUid;
}

string lastRecordPid;
int lastOffset = -1;
Json::Value records = Json::Value();

[Setting category="General" name="Number of ghosts to show" min="1" max="10"]
int g_numGhosts = 1;

[Setting category="General" name="Ghost rank offset" min="0" max="100"]
int g_ghostRankOffset = 0;

[Setting category="General" name="Enable Ghosts"]
bool g_enableGhosts = true;

void Update(float dt) {
    if (g_enableGhosts && !previousEnableGhosts) {
        startnew(MapCoro);
        startnew(LoadMapRecords);
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

array<string> UpdateMapRecords() {
    if (!permissionsOkay || api is null) return array<string>();

    string currentMap = CurrentMap;
    if (currentMap == "") return array<string>();

    if (records.GetType() != Json::Type::Array || int(records.Length) < g_numGhosts || lastOffset != g_ghostRankOffset) {
        lastOffset = g_ghostRankOffset;
        Json::Value mapRecords = api.GetMapRecords("Personal_Best", currentMap, true, g_numGhosts, g_ghostRankOffset);
        auto tops = mapRecords['tops'];
        if (tops.GetType() != Json::Type::Array) {
            if (mapRecords.Length == 0) {
                warn('api did not return an array for records; instead got: ' + Json::Write(mapRecords));
                NotifyWarn("API did not return map records.");
            }
            return array<string>();
        }
        records = tops[0]['top'];
    }
    array<string> pids = {};
    if (records.GetType() == Json::Type::Array) {
        for (uint i = 0; i < records.Length; i++) {
            auto item = records[i];
            pids.InsertLast(item['accountId']);
        }
    }
    if (pids.Length == 0) {
        log("No records found for map: " + currentMap, LogLevel::Warn, 128, "UpdateMapRecords");
        NotifyWarn("No records found for map: " + currentMap);
        return pids;
    }
    lastRecordPid = pids[pids.Length - 1];
    return pids;
}

void LoadMapRecords() {
    if (!permissionsOkay) return;

    array<string> pids = UpdateMapRecords();
    if (pids.Length > 0) {
        log("Loaded records for map: " + CurrentMap, LogLevel::Info, 141, "LoadMapRecords");
        ToggleLoadedGhosts(pids);
    }
}

void ToggleLoadedGhosts(array<string> pids) {
    NotifyInfo("Toggling " + pids.Length + " ghosts...");

    for (uint i = 0; i < pids.Length; i++) {
        ToggleGhost(pids[i], false);
    }

    for (uint i = g_ghostRankOffset; int(i) < g_ghostRankOffset + g_numGhosts && i < pids.Length; i++) {
        ToggleGhost(pids[i], true);
    }
}

void ToggleGhost(const string &in playerId, bool enable) {
    if (!permissionsOkay) return;

    bool currentState;
    if (ghostStates.Get(playerId, currentState)) {
        if (currentState == enable) {
            return;
        }
    }

    log((enable ? "Enabling" : "Disabling") + " ghost for playerId: " + playerId, LogLevel::Info, 168, "ToggleGhost");
    MLHook::Queue_SH_SendCustomEvent(g_MLHookCustomEvent, {playerId});
    ghostStates[playerId] = enable;
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

class NadeoApi {
    string liveSvcUrl;

    NadeoApi() {
        NadeoServices::AddAudience("NadeoLiveServices");
        liveSvcUrl = NadeoServices::BaseURLLive();
    }

    void AssertGoodPath(const string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            throw("API Paths should start with '/'!");
        }
    }

    const string LengthAndOffset(uint length, uint offset) {
        return "length=" + length + "&offset=" + offset;
    }

    Json::Value CallLiveApiPath(const string &in path) {
        AssertGoodPath(path);
        return FetchLiveEndpoint(liveSvcUrl + path);
    }

    Json::Value GetMapRecords(const string &in seasonUid, const string &in mapUid, bool onlyWorld = true, uint length=5, uint offset=0) {
        string qParams = onlyWorld ? "?onlyWorld=true" : "";
        if (onlyWorld) qParams += "&" + LengthAndOffset(length, offset);
        return CallLiveApiPath("/api/token/leaderboard/group/" + seasonUid + "/map/" + mapUid + "/top" + qParams);
    }
}

Json::Value FetchLiveEndpoint(const string &in route) {
    log("[FetchLiveEndpoint] Requesting: " + route, LogLevel::Info, 217, "LengthAndOffset");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}