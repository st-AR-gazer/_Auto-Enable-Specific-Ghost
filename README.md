# Auto Enable Specific Ghost

... is a forked plugin from XertroV's "Too Many Ghosts" plugin, the aim of this plugin is to automate the process of loading World Record ghosts for maps in Trackmania.

## Overview

When in a map, the script automatically fetches and loads the World Record ghost for the currently played map. 

## Features

- Checks for necessary permissions before attempting to fetch ghosts.
- Interfaces with the Nadeo API to fetch the best record for the current map.
- Loads the fetched ghost into the game for live comparison.

## Prerequisites

- [Trackmania](http://trackmania.com/) game installed
- Necessary permissions granted for viewing and playing records (a club subscription).

## How It Works

1. **Permissions Check:** Before any operations, the script checks for required permissions. If permissions are lacking, the script provides a warning and halts execution.
2. **Map Monitoring:** The script continuously monitors the currently played map. On change, it fetches the World Record ghost for the new map.
3. **Nadeo API Calls:** To fetch record details, the script interfaces with the Nadeo API. 
4. **Ghost Loading:** Once the record details are fetched, the script loads the World Record ghost into the game.

## Credits

- **Original Plugin:** XertroV's "Too Many Ghosts".
- **Authors:** ar..... / AR_-_ 

## License

The Unlicense
