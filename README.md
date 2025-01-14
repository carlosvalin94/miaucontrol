# Miaucontrol

Simple GUI Application to control my Elgato Key Light

# Requirements

Operating System: Linux (any modern distribution).

Avahi: Required for device discovery.

Python: Version 3.6 or higher.

Python Libraries:
PyGObject (Gtk 4.0)
Requests

Compatible Hardware: Elgato Key Light (API HTTP on port 9123).

Local Network: Both the PC and Elgato Key Light must be on the same network. 

## Installation


You can install it by running this command in the script's directory:

sh miaucontrol.sh

## To uninstall

Just launch the script again, It will detect it and ask for removal

### Current UI
![Screenshot From 2025-01-10 18-27-55](https://github.com/user-attachments/assets/aab0b587-3d62-42a2-9a54-ce4f580f311d)

![Screenshot From 2025-01-10 18-25-15](https://github.com/user-attachments/assets/66218190-43a7-4d12-9b70-e241535eb591)

### Hint

The app will automatically detect the light's IP. If it doesn't, you can enter the IP manually. To find it, you can use the following command:

avahi-browse -r -t _elg._tcp

### I need your help

I don't have much time to spend on this project. If you do, feel free to fork it and upload the app to Flathub or Snapcraft.
