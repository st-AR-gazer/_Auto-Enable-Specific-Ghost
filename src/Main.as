void Main() {
    PermsCheck();
    if (!permissionsOkay) return;

    FetchManifest();

    @api = NadeoApi();
    MLHook::RequireVersionApi('0.3.1');
    startnew(MapCoro);
}

[Setting category="General" name="Number of ghosts to show" min="1" max="10"]
int g_numGhosts = 1;

[Setting category="General" name="Ghost rank offset" min="0" max="100"]
int g_ghostRankOffset = 0;

[Setting category="General" name="Enable Ghosts"]
bool g_enableGhosts = true;

[Setting category="General" name="PLEASE NOTE: Changing these settings will require a map reload! (It's only checked when outside of map)"]
string g_note = "";