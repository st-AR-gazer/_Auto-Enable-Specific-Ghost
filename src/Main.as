NadeoApi@ api;
bool permissionsOkay = false;

void Main() {
    CheckRequiredPermissions();
    if (enableGhosts) return;
    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
    startnew(MapCoro);
}

string s_currMap = "";

void MapCoro() {
    while(true) {
        sleep(1500);
        if (s_currMap != CurrentMap) {
            s_currMap = CurrentMap;
            ResetToggleCache();
            LoadWRGhost();
        }
    }
}

dictionary toggleCache;

void ResetToggleCache() {
    toggleCache.DeleteAll();
    records = Json::Value();
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

[Setting category="General" name="Enable Ghosts"]
bool enableGhosts = true;

[Setting category="General" name="Set start auto load position" description="Set the position of the record to load, 1 = 1st place [...] 41 = 41st, etc."]
int setOffset = 0;

[Setting category="General" name="Set load range" description="Set the range of records to load, 1 = 1st place, 2 = 1st and 2nd, etc."]
int setRange = 1;

Json::Value records = Json::Value();
array<string> UpdateMapRecords() {
    if (!permissionsOkay) return array<string>();
    Json::Value mapRecords = api.GetMapRecords("Personal_Best", CurrentMap, true, setRange, setOffset);
    auto tops = mapRecords['tops'];
    if (tops.GetType() != Json::Type::Array) {
        log('api did not return an array for records; instead got: ' + Json::Write(mapRecords), LogLevel::Warn, 61);
        NotifyWarn("API did not return map records.");
        return array<string>();
    }
    records = tops[0]['top'];
    if (records is null) return array<string>();
    array<string> pids = {};
    if (records.GetType() == Json::Type::Array && records.Length > 0) {
        auto item = records[0];
        pids.InsertLast(item['accountId']);
    }
    return pids;
}

void LoadWRGhost() {
    array<string> pids = UpdateMapRecords();
    if (pids.Length > 0) {

        pids_Glob = pids;
        ToggleGhost(pids[0]);
    }
}

array<string> pids_Glob = {};

void ToggleGhost(const string &in playerId) {
    if (!permissionsOkay) return;
    MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", {playerId});
}

void Update() {

    if (!permissionsOkay) return;
    
    if (!enableGhosts) return;

    if (CurrentMap.Length <= 0) return;
    if (records is null) return;
    
    
    if (enableGhosts) {
        array<string> pids = pids_Glob;
        ToggleGhost(pids[0]);
    }
}

/*
API
*/

void log_trace(const string &in msg) {
    trace(msg);
}

class NadeoApi {
    string liveSvcUrl;
    NadeoApi() {
        NadeoServices::AddAudience("NadeoLiveServices");
        liveSvcUrl = NadeoServices::BaseURLLive();
    }
    void AssertGoodPath(const string &in path) {
        if (path.Length <= 0 || !path.StartsWith("/")) {
            log("API Paths should start with '/'!", LogLevel::Error, 123);
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
    log("Fetching: " + route, LogLevel::Info, 141);
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}