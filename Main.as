NadeoApi@ api;
bool permissionsOkay = false;

void Main() {
    CheckRequiredPermissions();
    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
    startnew(MapCoro);
}

void CheckRequiredPermissions() {
    permissionsOkay = Permissions::ViewRecords() && Permissions::PlayRecords();
    if (!permissionsOkay) {
        NotifyWarn("Your edition of the game does not support playing against record ghosts.\n\nThis plugin won't work, sorry :(.");
        while(true) { sleep(10); }
    }
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
        Notify("Loading WR ghost...");
        ToggleGhost(pids[0]);
    }
}

void ToggleGhost(const string &in playerId) {
    if (!permissionsOkay) return;
    MLHook::Queue_SH_SendCustomEvent("TMGame_Record_ToggleGhost", {playerId});
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

/*
UI STUFF
*/

void Notify(const string &in msg) {
    UI::ShowNotification("Auto Load WR Ghost", msg, vec4(.2, .8, .5, .3));
}

void NotifyWarn(const string &in msg) {
    UI::ShowNotification("Auto Load WR Ghost", msg, vec4(1, .5, .1, .5), 10000);
}
