#!/bin/bash

# Installation directory
INSTALL_DIR="$HOME/.local/share/applications"
SCRIPT_NAME="miaucontrol.py"
DESKTOP_NAME="miaucontrol.desktop"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"
DESKTOP_PATH="$INSTALL_DIR/$DESKTOP_NAME"

# Function to install
install() {
    echo "Installing Miaucontrol..."

    # Create the installation directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"

    # Copy the Python script
    echo "Copying the Python script..."
    cat << 'EOF' > "$SCRIPT_PATH"
import gi
import requests
import os
import subprocess

gi.require_version("Gtk", "4.0")
from gi.repository import Gtk


class KeyLightController(Gtk.Application):
    def __init__(self):
        super().__init__()
        self.window = None
        self.ip = self.detect_ip() or self.load_ip() or "192.168.0.3"

    def detect_ip(self):
        """Attempt to detect the IP address of the light using avahi-browse."""
        try:
            # Run avahi-browse command to find the Elgato Key Light
            result = subprocess.run(
                ["avahi-browse", "-r", "-t", "_elg._tcp"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            # Look for the line containing the address information
            for line in result.stdout.splitlines():
                if "address" in line and "_elg._tcp" in line:
                    # Extract and return the IP address
                    parts = line.split()
                    for part in parts:
                        if part.startswith("[") and part.endswith("]"):
                            return part.strip("[]")
        except Exception as e:
            print(f"Error detecting IP: {e}")
        return None

    def do_activate(self):
        if not self.window:
            self.window = Gtk.ApplicationWindow(application=self)
            self.window.set_title("Miaucontrol")
            self.window.set_default_size(300, 200)

            # Create the main layout
            layout = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
            self.window.set_child(layout)

            # IP field
            self.ip_entry = Gtk.Entry()
            self.ip_entry.set_text(self.ip)
            layout.append(Gtk.Label(label="Light IP:"))
            layout.append(self.ip_entry)

            # Action buttons
            buttons = [
                ("Turn On", self.switch_on),
                ("Turn Off", self.switch_off),
                ("Brightness +", self.brightness_up),
                ("Brightness -", self.brightness_down),
                ("Temperature +", self.temperature_up),
                ("Temperature -", self.temperature_down),
            ]

            for label, callback in buttons:
                button = Gtk.Button(label=label)
                button.connect("clicked", callback)
                layout.append(button)

            # Save IP button
            save_button = Gtk.Button(label="Save IP")
            save_button.connect("clicked", self.save_ip)
            layout.append(save_button)

        self.window.show()

    def load_ip(self):
        """Load the IP from a file."""
        if os.path.exists("elgato_ip.txt"):
            with open("elgato_ip.txt", "r") as file:
                return file.read().strip()
        return None

    def save_ip(self, button=None):
        """Save the IP to a file."""
        self.ip = self.ip_entry.get_text().strip()
        if self.ip:
            with open("elgato_ip.txt", "w") as file:
                file.write(self.ip)
            self.show_message("Success", "IP saved successfully.")
        else:
            self.show_message("Error", "Cannot save an empty IP.")

    def show_message(self, title, message):
        """Display a message in a dialog box."""
        dialog = Gtk.MessageDialog(
            transient_for=self.window,
            modal=True,
            text=title,
        )
        dialog.format_secondary_text(message)
        dialog.add_buttons(Gtk.ButtonsType.OK)
        dialog.connect("response", lambda d, r: d.destroy())
        dialog.show()

    def send_request(self, data):
        """Send a PUT request to the light."""
        url = f"http://{self.ip_entry.get_text().strip()}:9123/elgato/lights"
        try:
            response = requests.put(url, json=data)
            if response.status_code == 200:
                self.show_message("Success", "Action performed successfully.")
            else:
                self.show_message("Error", f"Error: {response.status_code}")
        except requests.exceptions.RequestException:
            self.show_message("Error", "Could not connect to the light.")

    def switch_on(self, button):
        """Turn the light on."""
        self.send_request({"numberOfLights": 1, "lights": [{"on": 1}]})

    def switch_off(self, button):
        """Turn the light off."""
        self.send_request({"numberOfLights": 1, "lights": [{"on": 0}]})

    def brightness_up(self, button):
        """Increase brightness incrementally."""
        current_brightness = self.get_current_brightness()
        new_brightness = min(current_brightness + 10, 100)  # Ensure brightness does not exceed 100%
        self.send_request({"numberOfLights": 1, "lights": [{"brightness": new_brightness}]})

    def brightness_down(self, button):
        """Decrease brightness incrementally."""
        current_brightness = self.get_current_brightness()
        new_brightness = max(current_brightness - 10, 0)  # Ensure brightness does not fall below 0
        self.send_request({"numberOfLights": 1, "lights": [{"brightness": new_brightness}]})

    def temperature_up(self, button):
        """Increase color temperature incrementally."""
        current_temperature = self.get_current_temperature()
        new_temperature = min(current_temperature + 500, 6500)  # Ensure temperature does not exceed 6500K
        self.send_request({"numberOfLights": 1, "lights": [{"temperature": new_temperature}]})

    def temperature_down(self, button):
        """Decrease color temperature incrementally."""
        current_temperature = self.get_current_temperature()
        new_temperature = max(current_temperature - 500, 2700)  # Ensure temperature does not fall below 2700K
        self.send_request({"numberOfLights": 1, "lights": [{"temperature": new_temperature}]})

    def get_current_brightness(self):
        """Get the current brightness of the light."""
        url = f"http://{self.ip_entry.get_text().strip()}:9123/elgato/lights"
        try:
            response = requests.get(url)
            if response.status_code == 200:
                data = response.json()
                return data["lights"][0]["brightness"]
            else:
                self.show_message("Error", f"Error retrieving brightness: {response.status_code}")
                return 50  # Default value if brightness cannot be retrieved
        except requests.exceptions.RequestException:
            self.show_message("Error", "Could not connect to the light.")
            return 50  # Default value if unable to connect

    def get_current_temperature(self):
        """Get the current temperature of the light."""
        url = f"http://{self.ip_entry.get_text().strip()}:9123/elgato/lights"
        try:
            response = requests.get(url)
            if response.status_code == 200:
                data = response.json()
                return data["lights"][0]["temperature"]
            else:
                self.show_message("Error", f"Error retrieving temperature: {response.status_code}")
                return 4000  # Default value if temperature cannot be retrieved
        except requests.exceptions.RequestException:
            self.show_message("Error", "Could not connect to the light.")
            return 4000  # Default value if unable to connect


def main():
    app = KeyLightController()
    app.run()


if __name__ == "__main__":
    main()
EOF

    # Copy the .desktop file
    echo "Copying the .desktop file..."
    cat << EOF > "$DESKTOP_PATH"
[Desktop Entry]
Version=1.1
Type=Application
Name=Miaucontrol
Icon=night-light-symbolic
Exec=sh -c "python3 $HOME/.local/share/applications/miaucontrol.py"
Categories=AudioVideo;
EOF

    # Give execution permissions to the script
    chmod +x "$SCRIPT_PATH"

    # Notify the user
    echo "Miaucontrol installed successfully."
}

# Function to uninstall
uninstall() {
    echo "Uninstalling Miaucontrol..."

    # Remove the files
    rm -f "$SCRIPT_PATH" "$DESKTOP_PATH"

    # Notify the user
    echo "Miaucontrol uninstalled successfully."
}

# Function to display the menu
show_menu() {
    echo "----------------------------"
    echo "     Installation Menu"
    echo "----------------------------"
    if [ -f "$SCRIPT_PATH" ] && [ -f "$DESKTOP_PATH" ]; then
        echo "1) Uninstall Miaucontrol"
        echo "2) Exit"
        read -p "Select an option (1/2): " option
        case $option in
            1)
                uninstall
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid option. Exiting."
                exit 1
                ;;
        esac
    else
        echo "1) Install Miaucontrol"
        echo "2) Exit"
        read -p "Select an option (1/2): " option
        case $option in
            1)
                install
                ;;
            2)
                exit 0
                ;;
            *)
                echo "Invalid option. Exiting."
                exit 1
                ;;
        esac
    fi
}

# Execute the menu
show_menu
