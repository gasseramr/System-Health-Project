
#!/bin/bash

# Log file location
LOGFILE="system_report.log"

# Function to log events to a file
log_event() {
  local message=$1
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $message" >> "$LOGFILE"
}

# Function to create a styled HTML report with table layout
generate_html_report() {
  local title=$1
  local content=$2
  local filename=$3

  cat <<EOF > "$filename"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 20px;
      background-color: #f4f4f9;
      color: #333;
    }
    h1 {
      text-align: center;
      color: #4CAF50;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }
    table, th, td {
      border: 1px solid #ddd;
    }
    th, td {
      padding: 10px;
      text-align: left;
    }
    th {
      background-color: #4CAF50;
      color: white;
    }
    tr:nth-child(even) {
      background-color: #f9f9f9;
    }
    pre {
      background-color: #f8f9fa;
      padding: 15px;
      border: 1px solid #ccc;
      border-radius: 5px;
      overflow-x: auto;
    }
    footer {
      text-align: center;
      margin-top: 20px;
      font-size: 0.9em;
      color: #666;
    }
  </style>
</head>
<body>
  <h1>$title</h1>
  <div>
    $content
  </div>
  <footer>Generated on $(date)</footer>
</body>
</html>
EOF
}

# Function to get CPU information
cpu_info() {
  local output="<h3>CPU Information</h3><table>
    <tr><th>Parameter</th><th>Value</th></tr>
    $(lscpu | awk -F ':' '/Model name|CPU MHz/ {print "<tr><td>" $1 "</td><td>" $2 "</td></tr>"}')
  </table>
  <h3>CPU Performance</h3><pre>$(top -bn1 | grep 'Cpu(s)')</pre>"

  local filename="cpu_report.html"
  generate_html_report "CPU Information Report" "$output" "$filename"
  log_event "CPU report generated and saved as $filename"
  zenity --info --text="CPU report saved as $filename" --width=300 --height=100
}

# Function to get Disk information
disk_info() {
  local disk_table="<h3>Disk Information</h3><table>
    <tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Available</th><th>Use%</th><th>Mounted On</th></tr>
    $(df -h | awk 'NR>1 {print "<tr><td>" $1 "</td><td>" $2 "</td><td>" $3 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td></tr>"}')
  </table>"

  local smart_info="<h3>SMART Health</h3><table>
    <tr><th>Disk</th><th>Status</th><th>Details</th></tr>"
  for disk in /dev/sd*; do
    if sudo smartctl -H "$disk" &> /dev/null; then
      smart_info+="<tr><td>$disk</td><td>Healthy</td><td>$(sudo smartctl -H "$disk")</td></tr>"
    else
      smart_info+="<tr><td>$disk</td><td>Not Supported</td><td>SMART data not available</td></tr>"
    fi
  done
  smart_info+="</table>"

  local output="$disk_table $smart_info"
  local filename="disk_report.html"
  generate_html_report "Disk Information Report" "$output" "$filename"
  log_event "Disk report generated and saved as $filename"
  zenity --info --text="Disk report saved as $filename" --width=300 --height=100
}

# Function to get Memory information
memory_info() {
  local output="<h3>Memory Information</h3><table>
    <tr><th>Total</th><th>Used</th><th>Free</th><th>Shared</th><th>Cache</th><th>Available</th></tr>
    $(free -h | awk 'NR==2 {print "<tr><td>" $2 "</td><td>" $3 "</td><td>" $4 "</td><td>" $5 "</td><td>" $6 "</td><td>" $7 "</td></tr>"}')
  </table>"

  local filename="memory_report.html"
  generate_html_report "Memory Information Report" "$output" "$filename"
  log_event "Memory report generated and saved as $filename"
  zenity --info --text="Memory report saved as $filename" --width=300 --height=100
}

# Function to get Network information
network_info() {
  local ip_info="<h3>Network Interfaces</h3><pre>$(ip a)</pre>"
  local stats="<h3>Network Statistics</h3><pre>$(netstat -s)</pre>"

  local output="$ip_info $stats"
  local filename="network_report.html"
  generate_html_report "Network Information Report" "$output" "$filename"
  log_event "Network report generated and saved as $filename"
  zenity --info --text="Network report saved as $filename" --width=300 --height=100
}

# Function to get GPU information
gpu_info() {
  local output="<h3>GPU Information</h3>"

  if [[ "$(uname)" == "Linux" ]]; then
    # Check for NVIDIA GPU
    if command -v nvidia-smi &> /dev/null; then
      output+="<h4>NVIDIA GPU Info:</h4><pre>$(nvidia-smi)</pre>"
    # Check for AMD GPU
    elif command -v amdgpu-smi &> /dev/null; then
      output+="<h4>AMD GPU Info:</h4><pre>$(amdgpu-smi)</pre>"
    else
      output+="No compatible GPU tools found. Ensure you have the correct GPU drivers installed.\n"
    fi
  elif [[ "$(uname)" == "Darwin" ]]; then
    # For macOS, use system_profiler to get GPU info
    output+="<h4>macOS GPU Info:</h4><pre>$(system_profiler SPDisplaysDataType)</pre>"
  elif [[ "$(uname)" == "CYGWIN"* || "$(uname)" == "MINGW"* ]]; then
    # For WSL/MinGW, use Windows-specific tools
    output+="<h4>Windows GPU Info:</h4><pre>$(wmic path win32_VideoController get Name, AdapterRAM, DriverVersion)</pre>"
  else
    output+="GPU information is OS-specific and may not be available on this system.\n"
  fi

  local filename="gpu_report.html"
  generate_html_report "GPU Information Report" "$output" "$filename"
  log_event "GPU report generated and saved as $filename"
  zenity --info --text="GPU report saved as $filename" --width=400 --height=300
}

# Function to get System load information
system_load() {
  local output="<h3>System Load</h3><pre>$(uptime)</pre>
    <h3>CPU Usage</h3><pre>$(top -bn1 | grep 'Cpu(s)')</pre>
    <h3>Memory Usage</h3><pre>$(top -bn1 | grep 'Mem')</pre>
    <h3>Swap Usage</h3><pre>$(top -bn1 | grep 'Swap')</pre>"

  local filename="system_load_report.html"
  generate_html_report "System Load Report" "$output" "$filename"
  log_event "System load report generated and saved as $filename"
  zenity --info --text="System load report saved as $filename" --width=300 --height=100
}

# Function to display menu options
show_menu() {
  local choice=$(zenity --list --title="System Information" --column="Options" \
    "Generate CPU Report" \
    "Generate Disk Report" \
    "Generate Memory Report" \
    "Generate Network Report" \
    "Generate GPU Report" \
    "Generate System Load Report" \
    "Exit")

  case $choice in
    "Generate CPU Report") cpu_info ;;
    "Generate Disk Report") disk_info ;;
    "Generate Memory Report") memory_info ;;
    "Generate Network Report") network_info ;;
    "Generate GPU Report") gpu_info ;;
    "Generate System Load Report") system_load ;;
    "Exit") exit 0 ;;
    *) zenity --error --text="Invalid choice, please select a valid option." ;;
  esac
}

# Main loop
while true; do
  show_menu
done

