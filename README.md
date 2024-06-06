# Auto Enable Specific Ghost

Auto Enable Specific Ghost is a forked plugin from XertroV's "Too Many Ghosts" plugin, designed to automate the process of loading World Record ghosts for maps in Trackmania.

## Overview

This plugin automatically fetches and loads the World Record ghost for the currently loaded map, allowing players to compare their performance against the best without having to click a button / use a plugin to fetch a ghost.

## Features

- **Permissions Check:** Ensures necessary permissions are granted before attempting to fetch ghosts.
- **Nadeo API Integration:** Interfaces with the Nadeo API to fetch the best record for the current map.
- **Dynamic Ghost Loading:** Automatically loads the World Record ghost when a map changes or is loaded.
- **Settings Management:** Enables or disables ghosts dynamically based on user settings.

## Prerequisites

- [Trackmania](http://trackmania.com/) game installed
- Necessary permissions granted for viewing and playing records (a club subscription).

## How It Works

1. **Permissions Check:** Before any operations, the script checks for required permissions. If permissions are lacking, the script provides a warning and halts execution.
2. **Map Monitoring:** The script continuously monitors the currently played map. On change, it fetches the World Record ghost for the new map.
3. **Nadeo API Calls:** To fetch record details, the script interfaces with the Nadeo API.
4. **Ghost Loading:** Once the record details are fetched, the script loads the World Record ghost into the game.
5. **Settings Management:** When `g_enableGhosts` is toggled, the script dynamically hides or shows ghosts based on the latest settings.

## Installation

1. Download the plugin from the [GitHub repository](#).
2. Copy the plugin files into your Trackmania scripts directory.
3. Ensure you have the necessary permissions for viewing records.

## Usage

1. Launch Trackmania and start a map.
2. The plugin will automatically check permissions and fetch the World Record ghost.
3. Adjust settings in the plugin configuration if needed.

## Credits

- **Original Plugin:** XertroV's "Too Many Ghosts"
- **Authors:** ar..... / AR_-_

## License

This project is licensed under The Unlicense.
