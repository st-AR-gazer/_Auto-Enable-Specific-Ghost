void RenderMenu() {
    if (g_enableGhosts) {
        if (UI::MenuItem("\\$2c2" + Icons::SnapchatGhost + Icons::ToggleOn + "\\$z Auto Enable Specific Ghosts", "Ghosts are currently being enabled.")) {
            g_enableGhosts = false;
            previousEnableGhosts = true;
        }
    } else {
        if (UI::MenuItem("\\$c22" + Icons::SnapchatGhost + Icons::ToggleOff + "\\$z Auto Enable Specific Ghosts", "Ghosts are currently being disabled.")) {
            g_enableGhosts = true;
            previousEnableGhosts = false;
        }
    }
}