# CS:GO Keyframe Smoothing Script
[![ver][]](https://github.com/samisalreadytaken/keyframes)

Quick smooth camera animation creation.

![](../assets/image1.jpg)

[ver]: https://img.shields.io/badge/keyframes-v1.3.0-informational
[![](https://img.shields.io/badge/Video_demonstration-red?logo=youtube)](https://www.youtube.com/watch?v=fefwKjaQsOY)


## Installation
Manually download the repository ([`Code > Download ZIP`](https://github.com/samisalreadytaken/keyframes/archive/master.zip)), then extract and merge the `/csgo/` folder with your `/steamapps/common/Counter-Strike Global Offensive/csgo/` folder.

Alternatively run the installation script of your choice:

- [Batch](https://raw.githubusercontent.com/samisalreadytaken/keyframes/master/install.bat) <sub>NOTE: `curl` and `tar` are included in Windows 10 since 17063.</sub>
```
curl -s https://raw.githubusercontent.com/samisalreadytaken/keyframes/master/install.bat > install_keyframes.bat && cmd /C install_keyframes.bat && del install_keyframes.bat
```

- [Shell](https://raw.githubusercontent.com/samisalreadytaken/keyframes/master/install.sh)
```
sh <(curl -s https://raw.githubusercontent.com/samisalreadytaken/keyframes/master/install.sh)
```

## Usage
Use the console commands to load and control the script. It needs to be loaded each time the map is changed.

See the _Default Key Binds_ section below for the keys that are available for you to use by default. These do not modify your settings. Optionally, bind other keys to improve your workflow. Suggested keybinds can be found in [keyframes.cfg](csgo/cfg/keyframes.cfg) file.

Some features are only available via these custom binds.

Before enabling these key binds, make sure you have a backup of your own binds that would be modified. To revert any changes, you may use a different cfg file for convenience - such as [keyframes_off.cfg](csgo/cfg/keyframes_off.cfg).

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
`kf_undo`              | Undo last action
`kf_redo`              | Redo last action
`kf_undo_history`      | Show action history
---                    | ---
`kf_compile`           | Compile the keyframe data
`kf_smooth_angles`     | Smooth compiled animation angles
`kf_smooth_angles_exp` | Smooth compiled animation angles exponentially
`kf_smooth_origin`     | Smooth compiled animation origin
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
`kf_manipulator`       | Toggle 3D manipulator
`kf_select`            | Select and hold current keyframe
`kf_select_path`       | In edit mode, select animation path
`kf_see`               | In edit mode, see the current selection.
`kf_next`              | While holding a keyframe, select the next one
`kf_prev`              | While holding a keyframe, select the previous one
`kf_showkeys`          | In edit mode, toggle showing keyframes
`kf_showpath`          | In edit mode, toggle showing the animation path
---                    | ---
`kf_guides`            | Toggle camera guides
`kf_elements`          | Toggle between element selection and camera animation
`kf_createlight`       | Create a light
`script kf_setparams({})`| Set current element parameters
`kf_duplicate`         | Duplicate current element in place
---                    | ---
`script kf_fov(val)`   | Set FOV data on the selected keyframe
`script kf_roll(val)`  | Set camera roll on the selected keyframe
`script kf_frametime(val)`| Sets the time it takes to travel until the next keyframe
`script kf_samplecount(val)`| Sets how many samples to take until the next keyframe
---                    | ---
`script kf_transform()`| Rotate all keyframes around key with optional translation offset (idx,offset,rotation)
---                    | ---
`kf_loadfile`          | Load data file
`script kf_load(input)`| Load new data from file
`script kf_trim(val)`  | Trim compiled animation path to specified length. Specify second param for direction
`kf_trim_undo`         | Undo last trim action
---                    | ---
`kf_cmd`               | List all commands

Default Key Binds    | Command
:-------------------:| ------------------------------
`MOUSE1`             | `kf_add` / `kf_next`
`MOUSE2`             | `kf_remove` / `kf_prev` / Reset manipulator pivot
`E`                  | `kf_see`
`W` / `S`            | Set camera FOV
`CTRL`               | Rotate around the current keyframe / Snap current translation to world / Snap pivot to world

Custom Key Binds     | Command
:-------------------:|---------------
`Q`                  | Set camera roll (hold and move mouse while in keyframe view)
`R`                  | `kf_replace` / Toggle manipulator modes / Pan the camera (hold and move mouse while in keyframe view)
`T`                  | `kf_insert` / Toggle manipulation space
`F`                  | `kf_select` (Select element to hold) / `kf_select_path` (Select path slice to playback)
`G`                  | `kf_manipulator`
`H`                  | `kf_undo_history`
`Z`                  | `kf_undo`
`X`                  | `kf_redo`
`C`                  | `+kf_movedown` (hold to move the camera downwards)
`V`                  | `+kf_moveup` (hold to move the camera upwards)


### File export
You can open the exported file (`.log`) with any text editor. You must replace `L ` with blank, i.e. remove, for the data to work.

Once you have cleared the exported file, either copy and paste it all in the `keyframes_data.nut` file, or rename the file extension to `.nut` and add it in the data file with `IncludeScript("kf_data_00000000.nut")`.

The data name can only contain letters and numbers, it cannot start with a number. You can store as much data as you want, and load any at any time.

You may reload the files with `kf_loadfile`, load named data with `script kf_load()`.

You can convert old saved data to new version by loading and saving - `script kf_load( my_saved_data )`, `kf_savekeys`/`kf_savepath`.


### Implementation notes
Spline interpolation requires 4 keyframes to interpolate between 2 keyframes. For this reason the very first and the very last keyframes do not have animation paths leading to and from them, but they affect the interpolation of the keyframes next to them. If desired, `kf_auto_fill_boundaries` can be used to toggle automatic duplication of these boundary keyframes.

FOV values are interpolated between two consecutive _FOV keys_, independent of the pos-ang keys. The playback starts with FOV set to data on KEY 1. If KEY 1 FOV data is omitted, it is set to 90.

Modifying any keyframe requires compilation before seeing the changes in playback (`kf_play`) and in export (`kf_savepath`). `kf_preview` can be used to playback these changes without compilation.

You may also select a portion of the compiled path with `kf_select_path` to playback while fine tuning your path. Use MOUSE1/MOUSE2 to select/cancel the selection. Use `kf_play_loop` to loop the playback.

All keyframes can be rotated and offset at once using `kf_transform()`.

```
kf_transform( Vector offset )
kf_transform( Vector|null offset, Vector angles )
kf_transform( int pivot, Vector offset, Vector angles )
```

`pivot` is the index of a keyframe to pivot the transform. If index is -1, average position of all keyframes is used as pivot point; if index is -2, current camera position (player) is used as pivot point.

Examples:

`script kf_transform( Vector(0, 0, 64) )` moves all keyframes 64 units vertically.

`script kf_transform( null, Vector(0, 90, 0) )` rotates all keyframes 90 degrees around Z axis (yaw).

`script kf_transform( 4, null, Vector(0, 90, 0) )` rotates all keyframes 90 degrees around Z axis (yaw) pivoted on keyframe 4.

![](../assets/gizmo1.gif)

Use the 3D manipulator (`kf_manipulator`) to easily modify keyframes to see their effects on the live updated path. Press R to toggle manipulation modes, press T to toggle transformation space.

Hold CTRL (`+duck`) and MOUSE1 (`+attack`) to rotate around the current keyframe.


## Changelog
See [CHANGELOG.txt](CHANGELOG.txt)


## Licence
You are free to use, modify and share this script under the terms of the GNU GPLv2.0 licence. In short, you must keep the copyright notice, and make your modifications public under the same licence if you distribute it.

This script uses [vs_library](https://github.com/samisalreadytaken/vs_library).

[![](http://hits.dwyl.com/samisalreadytaken/keyframes.svg)](http://hits.dwyl.com/samisalreadytaken/keyframes)
