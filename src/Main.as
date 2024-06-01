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

void MapCoro() {
    while(true) {
        sleep(273);
        if (!g_enableGhosts) return;
        if (s_currMap != CurrentMap) {
            s_currMap = CurrentMap;
            ResetToggleCache();
            LoadMapRecords();
        }
    }
}

dictionary toggleCache;

void ResetToggleCache() {
    toggleCache.DeleteAll();
    records = Json::Value();
    lastRecordPid = "";
}

CTrackMania@ get_app() {
    return cast<CTrackMania>(GetApp());
}

CGameManiaAppPlayground@ get_cmap() {
    return app.Network.ClientManiaAppPlayground;
}

string get_CurrentMap() {
    auto map = GetApp().RootMap;
    if (map is null) return "";
    return map.MapInfo.MapUid;
}

string lastRecordPid;
int lastOffset = -1;
Json::Value records = Json::Value();

[Setting name="Number of ghosts to show" min="1" max="10"]
int g_numGhosts = 1;

[Setting name="Ghost rank offset" min="0" max="100"]
int g_ghostRankOffset = 0;

[Setting name="Enable Ghosts"]
bool g_enableGhosts = false;

void Update() {
    if (g_enableGhosts && !previousEnableGhosts) {
        startnew(MapCoro);
    }
    previousEnableGhosts = g_enableGhosts;
}

bool previousEnableGhosts = false;

array<string> UpdateMapRecords() {
    if (!permissionsOkay) return array<string>();
    if (records.GetType() != Json::Type::Array || int(records.Length) < g_numGhosts || lastOffset != g_ghostRankOffset) {
        lastOffset = g_ghostRankOffset;
        Json::Value mapRecords = api.GetMapRecords(g_leaderboard, CurrentMap, true, g_numGhosts, g_ghostRankOffset);
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
    lastRecordPid = pids[pids.Length - 1];
    return pids;
}

void LoadMapRecords() {
    if (!permissionsOkay) return;

    array<string> pids = UpdateMapRecords();
    if (pids.Length > 0) {
        log("Loaded records for map: " + CurrentMap, LogLevel::Info, 103, "LoadMapRecords");
        ToggleLoadedGhosts(pids);
    }
}

void ToggleLoadedGhosts(array<string> pids) {
    NotifyInfo("Toggling " + pids.Length + " ghosts...");
    for (uint i = 0; i < pids.Length; i++) {
        auto playerId = pids[i];
        ToggleGhost(playerId);
    }
}

void ToggleGhost(const string &in playerId) {
    if (!permissionsOkay) return;
    log("Toggling ghost for playerId: " + playerId, LogLevel::Info, 118, "ToggleGhost");
    MLHook::Queue_SH_SendCustomEvent(g_MLHookCustomEvent, {playerId});
    bool enabled = false;
    toggleCache.Get(playerId, enabled);
    toggleCache[playerId] = !enabled;
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
    log("[FetchLiveEndpoint] Requesting: " + route, LogLevel::Info, 156, "LengthAndOffset");
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start(); 
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}
