# CS:GO Keyframe Smoothing Script
[![ver][]](https://github.com/samisalreadytaken/keyframes)

Create smooth camera paths live in-game, in mere seconds.

You can manipulate any keyframe at any time. You can save your keyframes, or your compiled paths to come back to them at a later time.

[ver]: https://img.shields.io/badge/keyframes-v1.1.13-informational
[![](https://img.shields.io/badge/Video_demonstration-red?logo=youtube)](https://www.youtube.com/watch?v=NDczxKqJECY)

## Installation
Merge the `/csgo/` folder with your `/steamapps/common/Counter-Strike Global Offensive/csgo/` folder.

This only adds 8 files to your /csgo/ folder. It does not overwrite any game files, and it does not interfere with the game in any way. It is VAC safe, and you can only use this script on your own server.

### Downloading
**Method 1.**
Manually download the repo by clicking [**HERE**](https://github.com/samisalreadytaken/keyframes/archive/master.zip). Then extract the folder.

**Method 2.**
On Windows 10 17063 or later, run the [`install_keyframes.bat`](https://raw.githubusercontent.com/samisalreadytaken/keyframes/master/install_keyframes.bat) file to automatically download the script into your game files. It can also be used to update the script.

**Method 3.**
In bash, after changing the directory below to your Steam game library directory, use the following commands to install the script into your game files.
```
cd "C:/Program Files/Steam/steamapps/common/Counter-Strike Global Offensive/" && 
curl https://codeload.github.com/samisalreadytaken/keyframes/tar.gz/master | tar -xz --strip=1 keyframes-master/csgo
```

## Usage
Use the console commands to load and control the script. You need to load it each time you change the map.

See the _Default Key Binds_ section below for the keys that are available for you to use by default. These do not modify your settings. Optionally, bind your other keys to improve your workflow. You can find some examples at the bottom of the [keyframes.cfg](csgo/cfg/keyframes.cfg) file.

Before uncommenting the key binds in the config file, make sure you have a backup of your own binds that would be modified.

Command                | Description
---------------------- | -------------------
`exec keyframes`       | Load the script
---                    | ---
`kf_add`               | Add new keyframe
`kf_remove`            | Remove the selected keyframe
`kf_remove_undo`       | Undo last remove action
`kf_removefov`         | Remove the FOV data from the selected keyframe
`kf_clear`             | Remove all keyframes
`kf_insert`            | Insert new keyframe after the selected keyframe
`kf_replace`           | Replace the selected keyframe
`kf_replace_undo`      | Undo last replace action
---                    | ---
`kf_compile`           | Compile the keyframe data
`kf_play`              | Play the compiled data
`kf_stop`              | Stop playback
`kf_save`              | Save the compiled data
`kf_savekeys`          | Save the keyframe data
---                    | ---
`kf_mode_ang`          | Toggle stabilised angles algorithm (no camera roll)
---                    | ---
`kf_edit`              | Toggle edit mode
`kf_select`            | In edit mode, hold the current selection
`kf_see`               | In edit mode, see the current selection.
`kf_next`              | While holding a keyframe, select the next one
`kf_prev`              | While holding a keyframe, select the previous one
`kf_showkeys`          | In edit mode, toggle showing keyframes
`kf_showpath`          | In edit mode, toggle showing the path
---                    | ---
`script kf_fov(val)`   | Set FOV data on the selected keyframe
`script kf_roll(val)`  | Set camera roll on the selected keyframe
`script kf_res(val)`   | Set interpolation resolution
---                    | ---
`script kf_load(input)`| Load new data from file
---                    | ---
`kf_cmd`               | List all commands

Default Key Binds    | Command                        | Game command to listen
:-------------------:| ------------------------------ | ---------------------------
`MOUSE1`             | `kf_add`                       | `+attack`
`MOUSE2`             | `kf_remove`                    | `+attack2`
`E`                  | `kf_see`                       | `+use`
`A` / `D`            | (In see mode) Set camera roll  | `+moveleft` / `+moveright`
`W` / `S`            | (In see mode) Set camera FOV   | `+forward` / `+back`
`MOUSE1`             | (In see mode) `kf_next`        | `+attack`
`MOUSE2`             | (In see mode) `kf_prev`        | `+attack2`

Suggested Key Binds  | Command
:-------------------:|---------------
`F`                  | `kf_select`
`X`                  | `kf_insert`
`C`                  | `kf_replace`

### Exported file
You can open the exported file (`.log`) with any text editor. You must replace `L ` with blank, i.e. remove, for the data to work. Once you have cleared the exported file, copy and paste it in the `keyframes_data.nut` file, which you can also open with any text editor. The data name can only contain letters and numbers, it cannot start with a number. You can store as much data as you want, and load any at any time.

### Implementation notes
Position and angle values are interpolated using Catmull-Rom splines between two consecutive keyframes.

FOV values are linearly interpolated between two consecutive _FOV keys_, independent of the pos-ang keys. Thus, the FOV data on the very first (KEY 0) keyframe is discarded. The playback starts with FOV set to data on KEY 1. If KEY 1 FOV data is omitted, it is set to 90.

Modifying the position or angle data, including camera roll, of any key requires compilation before seeing the changes in playback. Whereas for FOV datas, the user can see their changes in playback without having to recompile.

## Changelog
See [CHANGELOG.txt](CHANGELOG.txt)

## License
You are free to use, modify and share this script under the terms of the GNU GPLv2.0 license. In short, you must keep the copyright notice, and make your modifications public under the same license if you distribute it.

This script uses [vs_library](https://github.com/samisalreadytaken/vs_library).

[![](http://hits.dwyl.com/samisalreadytaken/keyframes.svg)](http://hits.dwyl.com/samisalreadytaken/keyframes)
