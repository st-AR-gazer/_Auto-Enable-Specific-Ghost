NadeoApi@ api;
bool permissionsOkay = false;
//bool enableGhosts = false;

void Main() {
    CheckRequiredPermissions();
    if (g_windowVisible) return;
    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
    startnew(MapCoro);
}

void RenderMenu() {
    if (g_windowVisible) {
        if (UI::MenuItem("\\$2c2" + Icons::WikipediaW + Icons::Registered + Icons::ToggleOn + "\\$z Auto Load WR Ghost", "Ghost is currently enabled.")) {
            g_windowVisible = false;
        }
    } else {
        if (UI::MenuItem("\\$c22" + Icons::WikipediaW + Icons::Registered + Icons::ToggleOff + "\\$z Auto Load WR Ghost", "Ghost is currently disabled.")) {
            g_windowVisible = true;
        }
    }
}

void CheckRequiredPermissions() {
    permissionsOkay = Permissions::ViewRecords() && Permissions::PlayRecords();
    if (!permissionsOkay) {
        NotifyWarn("Your edition of the game does not support playing against record ghosts.\n\nThis plugin won't work, sorry :(");
        while(true) { sleep(10); }
    }
}

string storedCurrentMap = "";

void MapCoro() {
    while(true) {
        sleep(1500);
        if (storedCurrentMap != CurrentMap) {
            storedCurrentMap = CurrentMap;
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

[Setting hidden]
bool g_windowVisible = false;

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

Json::Value records = Json::Value();

array<string> UpdateMapRecords() {
    if (!permissionsOkay) return array<string>();
    Json::Value mapRecords = api.GetMapRecords("Personal_Best", CurrentMap, true, 1, 0);
    auto tops = mapRecords['tops'];
    if (tops.GetType() != Json::Type::Array) {
        warn('api did not return an array for records; instead got: ' + Json::Write(mapRecords));
        // NotifyWarn("API did not return map records.");
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
        NotifyInfo("Loading WR ghost...");
        ToggleGhost(pids[0]);
    }
}

void ToggleGhost(const string &in playerId) {
    if (!permissionsOkay) return;
    MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", {playerId});
}

void Update() {
    if (!permissionsOkay) return;
    if (CurrentMap.Length <= 0) return;
    if (records is null) return;
    
    if (!enableGhosts) return;
    
    if (g_windowVisible) {
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
            throw("API Paths should start with '/'!");
        }
    }
}

void Update() {
    if (!permissionsOkay) return;
    if (CurrentMap.Length <= 0) return;
    if (records is null) return;
    
    if (!enableGhosts) return;
    
    if (g_windowVisible) {
        ToggleGhost(pids[0]);
    }
}
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
    log_trace("[FetchLiveEndpoint] Requesting: " + route);
    while (!NadeoServices::IsAuthenticated("NadeoLiveServices")) { yield(); }
    auto req = NadeoServices::Get("NadeoLiveServices", route);
    req.Start();
    while(!req.Finished()) { yield(); }
    return Json::Parse(req.String());
}