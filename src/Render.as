void RenderMenu() {
    if (enableGhosts) {
        if (UI::MenuItem("\\$2c2" + Icons::WikipediaW + Icons::Registered + Icons::ToggleOn + "\\$z Auto Load WR Ghost", "Ghost is currently enabled.")) {
            enableGhosts = false;
        }
    } else {
        if (UI::MenuItem("\\$c22" + Icons::WikipediaW + Icons::Registered + Icons::ToggleOff + "\\$z Auto Load WR Ghost", "Ghost is currently disabled.")) {
            enableGhosts = true;
        }
    }
}