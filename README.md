<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/e53ed013-8a7a-40b8-8c4e-a7dfdce15e93">
  <img alt="EnvyControl Logo" src="https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/e53ed013-8a7a-40b8-8c4e-a7dfdce15e93" height="150px">
</picture>
  <br>
  Optimus GPU Switcher
</div>
<br>

# Optimus GPU Switcher KDE Plasma Widget
KDE Plasma widget to change the GPU mode using the [EnvyControl](https://github.com/bayasdev/envycontrol) command line tool.

## Install

### Dependencies

- This widget depends on [EnvyControl](https://github.com/bayasdev/envycontrol), so you must install it first.
- One of the following tools is required for notifications to work. Note that in many distros at least one of the two is installed by default, check it out.
  - [notify-send](https://www.commandlinux.com/man-page/man1/notify-send.1.html) - a program to send desktop notifications.
  - [zenity](https://www.commandlinux.com/man-page/man1/zenity.1.html) - display GTK+ dialogs.

### KDE Store
You can find it in your software center, in the subcategories **Plasma Addons > Plasma Widgets**.  

Or you can download or install it directly from the [KDE Store](https://store.kde.org/p/2053791/)

### Manually
1. Download the release.
2. Unzip it into a folder.
3. Run from a terminal the command `plasmapkg2 -i [widget folder name]`.

## Disclaimer
I'm not a widget or KDE developer, I did this by looking at other widgets, using AI chatbots, consulting documentation, etc. So use it at your own risk.
Any recommendations and contributions are welcome.

## Helpful commands for weird issues

### Restart Plasma desktop
`killall plasmashell && kstart5 plasmashell`

### Clear the KDE widgets cache

1. Stop the Plasma desktop: `killall plasmashell`
2. Clear the Plasma cache: `rm -rf ~/.cache/plasma*` for general issues or `rm ~/.cache/icon-cache.kcache` for icon issues.
3. Restart the Plasma desktop: `kstart5 plasmashell`

## Screenshots
- Screenshots running on a laptop with AMD integrated graphics and an Nvidia GPU.
- The icon changes depending on the current mode and the manufacturer of the processor (Intel, AMD, or "other" in case it is another manufacturer or in case it is one of the first two and it cannot detect it).

![Screenshot_20230705_151601](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/0c879552-93e3-49d9-ac56-d05284ab5c16)

![Screenshot_20230703_154142](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/b6865586-167e-4c87-af91-76eb1794165d)
