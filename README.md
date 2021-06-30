# CS:GO Keyframe Smoothing Script
[![ver][]](https://github.com/samisalreadytaken/keyframes)

Quick smooth camera path creation.

![](../assets/image1.jpg)

[ver]: https://img.shields.io/badge/keyframes-v1.2.1-informational
[![](https://img.shields.io/badge/Video_demonstration-red?logo=youtube)](https://www.youtube.com/watch?v=NDczxKqJECY)


## Installation
Merge the `/csgo/` folder with your `/steamapps/common/Counter-Strike Global Offensive/csgo/` folder.

This only adds 8 files to your /csgo/ folder. It does not overwrite any game files, and it does not interfere with the game in any way. You can only use this script on your own server.


### Downloading
**Method 1.**
Manually download the repository ([`Code > Download ZIP`](https://github.com/samisalreadytaken/keyframes/archive/master.zip)), then extract the folder.

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
`kf_removefov`         | Remove the FOV data from the selected keyframe
`kf_clear`             | Remove all keyframes
`kf_insert`            | Insert new keyframe before the selected keyframe
`kf_replace`           | Replace the current keyframe
`kf_copy`              | Set player pos/ang to the current keyframe
`kf_undo`              | Undo last keyframe modify action
`kf_redo`              | Redo
`kf_undo_history`      | Show undo history
---                    | ---
`kf_compile`           | Compile the keyframe data
`kf_smooth_angles`     | Smooth compiled path angles
`kf_smooth_angles_exp` | Smooth compiled path angles exponentially
`kf_smooth_origin`     | Smooth compiled path origin
`kf_play`              | Play the compiled data
`kf_play_loop`         | Play the compiled data looped
`kf_preview`           | Play the keyframe data without compiling
`kf_stop`              | Stop playback
`kf_savepath`          | Export the compiled data
`kf_savekeys`          | Export the keyframe data
---                    | ---
`kf_mode_angles`       | Cycle through angle interpolation types
`kf_mode_origin`       | Cycle through position interpolation types
`kf_auto_fill_boundaries`| Duplicate the first and last keyframes in compilation
---                    | ---
`kf_edit`              | Toggle edit mode
`kf_translate`         | Toggle 3D translation manipulator
`kf_select_path`       | In edit mode, select path
`kf_see`               | In edit mode, see the current selection.
`kf_next`              | While holding a keyframe, select the next one
`kf_prev`              | While holding a keyframe, select the previous one
`kf_showkeys`          | In edit mode, toggle showing keyframes
`kf_showpath`          | In edit mode, toggle showing the path
---                    | ---
`script kf_fov(val)`   | Set FOV data on the selected keyframe
`script kf_roll(val)`  | Set camera roll on the selected keyframe
`script kf_res(val)`   | Set interpolation sampling rate
---                    | ---
`script kf_transform()`| Rotate all keyframes around key with optional translation offset (idx,offset,rotation)
---                    | ---
`kf_loadfile`          | Load data file
`script kf_load(input)`| Load new data from file
`script kf_trim(val)`  | Trim compiled path to specified length. Specify second param for direction
`kf_trim_undo`         | Undo last trim action
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
`F`                  | `kf_select_path`
`G`                  | `kf_translate`
`Z`                  | `kf_undo`
`X`                  | `kf_redo`
`C`                  | `kf_replace`
`V`                  | `kf_insert`


### File export
You can open the exported file (`.log`) with any text editor. You must replace `L ` with blank, i.e. remove, for the data to work.

Once you have cleared the exported file, either copy and paste it all in the `keyframes_data.nut` file, or rename the file extension to `.nut` and add it in the data file with `IncludeScript("kf_data_00000000.nut")`.

The data name can only contain letters and numbers, it cannot start with a number. You can store as much data as you want, and load any at any time.

You may reload the files with `kf_loadfile`, load named data with `script kf_load()`.

You can convert old saved data to new version by loading and saving - `script kf_load( my_saved_data )`, `kf_savekeys`/`kf_savepath`.


### Implementation notes
Spline interpolation requires 4 keyframes to interpolate between 2 keyframes. For this reason the very first and the very last keyframes do not have paths leading to and from them, but they affect the interpolation of the keyframes next to them. If desired, `kf_auto_fill_boundaries` can be used to toggle automatic duplication of these boundary keyframes.

FOV values are interpolated between two consecutive _FOV keys_, independent of the pos-ang keys. The playback starts with FOV set to data on KEY 1. If KEY 1 FOV data is omitted, it is set to 90.

Modifying any keyframe requires compilation before seeing the changes in playback (`kf_play`) and in export (`kf_savepath`). `kf_preview` can be used to playback these changes without compilation.

You may also select a portion of the compiled path with `kf_select_path` to playback while fine tuning your path. Use MOUSE1/MOUSE2 to select/cancel the selection. Use `kf_play_loop` to loop the playback.

`kf_transform( int index, Vector offset, Vector rotation )`: index is the index of a keyframe to pivot the transform. If index is -1, average position of all keyframes is used as pivot point; if index is -2, current camera position (player) is used as pivot point.

Example: `script kf_transform( 2, null, Vector(0, 90, 0) )` rotates all keyframes 90 degrees horizontally (yaw) around keyframe 2.

Example: `script kf_transform( 0, Vector(0, 0, 64), null )` moves all keyframes 64 units vertically.

![](../assets/gizmo1.gif)

Use the translation manipulator (`kf_translate`) to easily move keyframes to see their effects on the live updated path.

Hold CTRL (`+duck`) and MOUSE1 (`+attack`) to rotate around the current keyframe.


## Changelog
See [CHANGELOG.txt](CHANGELOG.txt)


## License
You are free to use, modify and share this script under the terms of the GNU GPLv2.0 license. In short, you must keep the copyright notice, and make your modifications public under the same license if you distribute it.

This script uses [vs_library](https://github.com/samisalreadytaken/vs_library).

[![](http://hits.dwyl.com/samisalreadytaken/keyframes.svg)](http://hits.dwyl.com/samisalreadytaken/keyframes)
