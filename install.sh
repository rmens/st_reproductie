# Detect OS details
OS_ARCH=$(dpkg --print-architecture)

# Install necessary packages
apt update -y
apt -qq -y install ffmpeg

# Configure directories
mkdir -p /var/audio
mkdir -p /opt/stereotool

# Download and install StereoTool
if [ "$OS_ARCH" == "amd64" ]; then
    wget https://download.thimeo.com/stereo_tool_cmd_64 -O /opt/stereotool/st_standalone
elif [ "$OS_ARCH" == "arm64" ]; then
    wget https://www.stereotool.com/download/stereo_tool_pi2_64 -O /opt/stereotool/st_standalone
fi

chmod +x /opt/stereotool/st_standalone

# Valid input
wget https://audio.zuidwestfm.nl/2023-09-23_03.mp3 -O /var/audio/test.mp3

# Patch ST config
/opt/stereotool/st_standalone -X /etc/st.ini
awk -i inplace '/^\[Stereo Tool Configuration\]/ { in_section=1; print; next } !/^\[/ && in_section { if ($0 ~ /^Port=/) { print "Port=9000"; next } if ($0 ~ /^Whitelist=/) { print "Whitelist=/0"; next } } { print }' "/etc/st.ini"

# Run it
ffmpeg -hide_banner -re -i /var/audio/test.mp3 -ar 48000 -sample_fmt s16 -f wav - | /opt/stereotool/st_standalone - /dev/null -w 9000 -r 48000 -q -s /etc/st.ini