string s_currMap = "";
bool mapRecordsLoaded = false;

void MapCoro() {
    while(true) {
        sleep(273);
        if (!g_enableGhosts) continue;
        if (s_currMap != CurrentMap) {
            s_currMap = CurrentMap;
            //log("Map changed to: " + s_currMap, LogLevel::Info, 22, "MapCoro");
            ResetToggleCache();
            //log("Reset toggle cache", LogLevel::Info, 24, "MapCoro");
            LoadMapRecords();
            //log("Loaded map records", LogLevel::Info, 26, "MapCoro");
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

bool IsInMap() {
    CTrackMania@ app = cast<CTrackMania>(GetApp());
    if (app is null) return false;

    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    return !(playground is null || playground.Arena.Players.Length == 0);
}

string get_CurrentMap() {
    if (IsInMap()) {
        auto app = get_app();
        if (app is null) return "";
        auto map = app.RootMap;
        if (map is null) return "";
        return map.MapInfo.MapUid;
    }
    return "";
}

array<string> UpdateMapRecords() {
    if (!permissionsOkay || api is null) return array<string>();

    string currentMap = CurrentMap;
    if (currentMap == "") return array<string>();

    if (records.GetType() != Json::Type::Array || int(records.Length) < g_numGhosts || lastOffset != g_ghostRankOffset) {
        lastOffset = g_ghostRankOffset;
        Json::Value mapRecords = api.GetMapRecords(g_leaderboard, currentMap, true, g_numGhosts, g_ghostRankOffset);
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
    string wrPid = "";
    if (records.GetType() == Json::Type::Array) {
        for (uint i = 0; i < records.Length; i++) {
            auto item = records[i];
            if (i == 0) {
                wrPid = item['accountId'];
            }
            pids.InsertLast(item['accountId']);
        }
    }
    lastRecordPid = wrPid;
    return pids;
}

void LoadMapRecords() {
    if (!permissionsOkay) return;

    array<string> pids = UpdateMapRecords();
    if (pids.Length > 0) {
        //log("Loaded records for map: " + CurrentMap, LogLevel::Info, 106, "LoadMapRecords");
        ToggleLoadedGhosts(pids);
    }
}
