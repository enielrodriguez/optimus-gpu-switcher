<div align="center">
<picture>
  <source media="(prefers-color-scheme: dark)" srcset="logo.png">
  <img alt="Logo" src="logo.png" height="150px">
</picture>
  <br>
  Optimus GPU Switcher
</div>
<br>

# Optimus GPU Switcher for KDE 6
KDE Plasma widget to change the GPU mode using the [EnvyControl](https://github.com/bayasdev/envycontrol) command line tool.

## Install

### Dependencies

- This widget depends on [EnvyControl](https://github.com/bayasdev/envycontrol), so you must install it first.
- One of the following tools is required for notifications to work. Note that in many distros at least one of the two is installed by default, check it out.
  - [notify-send](https://www.commandlinux.com/man-page/man1/notify-send.1.html) - a program to send desktop notifications.
  - [zenity](https://www.commandlinux.com/man-page/man1/zenity.1.html) - display GTK+ dialogs.

### From KDE Store
You can find it in your software center, in the subcategories `Plasma Addons > Plasma Widgets`.  
Or you can download or install it directly from the [KDE Store](https://store.kde.org/p/2138365/) website.

### Manually
- Download/clone this repo.
- Run from a terminal the command `plasmapkg2 -i [widget folder name]`.

## Disclaimer
I'm not a widget or KDE developer, I did this by looking at other widgets, using AI chatbots, consulting documentation, etc. So use it at your own risk.
Any recommendations and contributions are welcome.

## Screenshots
- Screenshots running on a laptop with AMD integrated graphics and an Nvidia GPU.
- The icon changes depending on the current mode and the manufacturer of the processor (Intel, AMD, or "other" in case it is another manufacturer or in case it is one of the first two and it cannot detect it).

![Screenshot_20230705_151601](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/0c879552-93e3-49d9-ac56-d05284ab5c16)

![Screenshot_20230830_180948](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/374276c8-8218-4730-812d-7478f7742a33)

![Screenshot_20230830_181404](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/3b7d0e25-e2a2-480a-9fac-8adc52df8e33)

![Screenshot_20231013_120727](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/56d6ea62-4e4e-4110-9ebd-9649dbf4f0e9)
