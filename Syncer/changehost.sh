#change hostname

echo "Changing host name to abiis-classroom"
sudo raspi-config nonint do_hostname abiis-classroom
echo "Stripping local from hostname"
raspi-config nonint do_hostname "$1". #strips .local from hostname.local
echo "Raspberry pi will now restart"
sudo reboot




