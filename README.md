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

A KDE Plasma 6 widget designed to switch between GPU modes using the [EnvyControl](https://github.com/bayasdev/envycontrol) tool.

## Installation

### Dependencies

- **[EnvyControl](https://github.com/bayasdev/envycontrol)** (required): Follow the EnvyControl documentation to install it via your distribution's package manager or `pip install python3-envycontrol`.
- A notification tool (one of the following is usually installed by default):
  - [notify-send](https://www.commandlinux.com/man-page/man1/notify-send.1.html)
  - [zenity](https://www.commandlinux.com/man-page/man1/zenity.1.html)

### From KDE Store
You can find it in your software center under `Plasma Addons > Plasma Widgets`, or install it directly from the [KDE Store](https://store.kde.org/p/2138365/).

### Manual Installation
1. Clone this repository:
   ```bash
   git clone https://github.com/enielrodriguez/optimus-gpu-switcher.git
   cd optimus-gpu-switcher
   ```
2. Install the widget using `kpackagetool6`:
   ```bash
   kpackagetool6 -t Plasma/Applet -i .
   ```
   *(To upgrade an existing installation, use `kpackagetool6 -t Plasma/Applet -u .`)*

## How to Use

1. Right-click on your KDE panel or desktop and select **Add Widgets...**.
2. Search for **Optimus GPU Switcher** and drag it to your panel or desktop.
3. Click the widget icon to switch GPU modes (Integrated, NVIDIA, or Hybrid) or right-click the widget to use the context menu actions.
4. When switching GPU modes, root privileges will be requested via Polkit (`pkexec`). Reboot your computer after switching for changes to take effect.

## Contribution

If you'd like to contribute to this project:
1. Fork the repository
2. Create a feature branch with your changes
3. Submit a Pull Request with a clear description of your changes

## Disclaimer
I'm not a widget or KDE developer, I did this by looking at other widgets, using AI chatbots, consulting documentation, etc. So use it at your own risk. Any recommendations and contributions are welcome.

## Screenshots
- Screenshots running on a laptop with AMD integrated graphics and an Nvidia GPU.
- The icon changes depending on the current mode and the manufacturer of the processor (Intel, AMD, or "other" in case it is another manufacturer or in case it is one of the first two and it cannot detect it).

![Screenshot_20230705_151601](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/0c879552-93e3-49d9-ac56-d05284ab5c16)

![Screenshot_20230830_180948](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/374276c8-8218-4730-812d-7478f7742a33)

![Screenshot_20230830_181404](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/3b7d0e25-e2a2-480a-9fac-8adc52df8e33)

![Screenshot_20231013_120727](https://github.com/enielrodriguez/optimus-gpu-switcher/assets/31964610/56d6ea62-4e4e-4110-9ebd-9649dbf4f0e9)
