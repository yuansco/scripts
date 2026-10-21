#!/bin/bash
# ==============================================================================
# Console Tool v2
# This script is used to connect console ports of Chromebooks via servo boards
# and hdctools (servod / dut-control), as well as provide ADB shell connection.
#
# Original Author: Yu-An Chen
# Refactored Version: 2.0 (based on v5.8)
# Last Modified: 2026/10/21
# ==============================================================================

# Script metadata
readonly SCRIPT_VERSION="2.0"
readonly LAST_MODIFIED="2026/10/21"
readonly DOWNLOAD_URL="https://raw.githubusercontent.com/yuansco/scripts/main/tools/console_tool_v2.sh"

# Default configuration paths
BOARD_LIST="${BOARD_LIST:-$HOME/workspace/board_list.sh}"
[[ -f "$BOARD_LIST" ]] || BOARD_LIST="$HOME/board_list.sh"

# Default board list template if file does not exist
DEFAULT_BOARD_LIST='#!/bin/bash
# Support board list:
# Format: "BoardName,ServodArgument,Servo_V4/p1,C2D2,Servo_micro,SuzyQable"
support_board=("Exit,Exit,N,N,N,N")                      #  0. Exit
support_board+=("osiris,brya -m osiris,Y,Y,N,Y")         #  1. brya/osiris
support_board+=("craask,nissa_craask,Y,Y,N,Y")           #  2. nissa/craask
support_board+=("rex,rex,Y,Y,N,Y")                       #  3. rex (baseboard)
support_board+=("kanix,rex_kanix,Y,Y,N,Y")               #  4. rex/kanix
support_board+=("fatcat,fatcat,Y,N,Y,Y")                 #  5. fatcat (baseboard)
support_board+=("kinmen,fatcat_kinmen,Y,N,Y,Y")          #  6. fatcat/kinmen
support_board+=("ocelot,ocelot_ite,Y,N,Y,Y")             #  7. ocelot (baseboard)
support_board+=("matsu,ocelot_matsu,Y,N,Y,Y")            #  8. ocelot/matsu
support_board+=("moonstone,fatcat_kinmen,Y,N,Y,Y")       #  9. fatcat/moonstone
support_board+=("caboc,brox_caboc,Y,N,Y,Y")              # 10. brox/caboc
support_board+=("aneto,bluey -m pic,Y,N,Y,Y")            # 11. bluey/aneto

ADB_IP="192.168.1.101"
'

# ------------------------------------------------------------------------------
# Terminal Colors & Logging
# ------------------------------------------------------------------------------
CLR_GREEN="\033[32;01m"
CLR_YELLOW="\033[33;01m"
CLR_RED="\033[41;01m"
CLR_CYAN="\033[96;01m"
CLR_RESET="\033[0m"

LOG()   { echo -e "${CLR_GREEN}[INFO ]${CLR_RESET} $*"; }
LOG_W() { echo -e "${CLR_YELLOW}[WARN ]${CLR_RESET} $*"; }
LOG_E() { echo -e "${CLR_RED}[ERROR]${CLR_RESET} $*"; }
LOG_D() { [[ "$debug_mode" == "Enable" ]] && echo -e "${CLR_CYAN}[DEBUG]${CLR_RESET} $*"; }

LOG_C() {
    echo -e "${CLR_CYAN}[CMD  ]${CLR_RESET} $*"
    "$@"
}

LOG_EVAL() {
    echo -e "${CLR_CYAN}[CMD  ]${CLR_RESET} $*"
    eval "$*"
}

exit_script() {
    local exit_code="${1:-0}"
    local indent=""
    if [[ "$1" == "-t" ]]; then
        indent="        "
        exit_code="${2:-0}"
    fi
    echo -e "${indent}Exit script..."
    exit "$exit_code"
}

# ------------------------------------------------------------------------------
# Help & Usage Info
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF

 Description:
   Console Tool v2
   Connects to Chromebook console ports via servo board and hdctools (servod).
   Original Author: Yu-An Chen
   Version: $SCRIPT_VERSION (Last modified: $LAST_MODIFIED)

 Usage:
   console [OPTIONS] [BOARD] [TARGET_PORT]

 Examples:
   (1) Print support board list:
       console -l

   (2) Connect DUT via servod:
       console <BOARD>
       e.g.: console rex

   (3) Open EC UART port:
       console ec

   (4) Run servod and open EC UART port:
       console <BOARD> ec

   (5) Open AP/BIOS UART port and record log via minicom:
       console ap -m -r

   (6) Connect to DUT Android shell via ADB:
       console adb

 Options:
   -c, --channel [CHAN]  Channel selection (release, local, latest, beta). Default: release
   -h, --help            Show this help message
   -l, --list            Print support board list
   -m, --minicom         Use minicom to open console port (default: picocom)
   -r, --record, --log   Record console session to log file
   -u, --update          Update script to latest version from remote repository
   -v, -V, --version     Print tool version

 Supported Targets:
   ec                    Embedded Controller console (ec_uart_pty)
   bios, ap, cpu         AP / BIOS / CPU console (cpu_uart_pty)
   gsc, ccd, cr50, ti50  GSC / CCD console (gsc_uart_pty / cr50_uart_pty)
   v4, servo_v4          Servo V4 / V4p1 console

 Exit Keybindings:
   picocom: Press [Ctrl]+[A], then [Ctrl]+[X]
   minicom: Press [Ctrl]+[A], then [Q] (or [X]), then [Enter]
   adb:     Press [Ctrl]+[D] or type "exit"

EOF
}

# ------------------------------------------------------------------------------
# Support Board List Loading & Parsing
# ------------------------------------------------------------------------------
board_name_arr=()
servod_target_arr=()
servov4_sup_arr=()
c2d2_sup_arr=()
servo_micro_sup_arr=()
suzyqable_sup_arr=()

load_board_list() {
    if [[ -f "$BOARD_LIST" ]]; then
        LOG "Loading $BOARD_LIST"
    else
        LOG_W "$BOARD_LIST does not exist."
        LOG "Creating default board list at $BOARD_LIST..."
        mkdir -p "$(dirname "$BOARD_LIST")"
        echo "$DEFAULT_BOARD_LIST" > "$BOARD_LIST"
    fi

    # Source the board list definition
    # shellcheck source=/dev/null
    source "$BOARD_LIST"

    # Reset arrays
    board_name_arr=()
    servod_target_arr=()
    servov4_sup_arr=()
    c2d2_sup_arr=()
    servo_micro_sup_arr=()
    suzyqable_sup_arr=()

    local entry b_name b_target b_v4 b_c2d2 b_micro b_suzy
    for entry in "${support_board[@]}"; do
        [[ -z "$entry" ]] && continue
        IFS=',' read -r b_name b_target b_v4 b_c2d2 b_micro b_suzy <<< "$entry"
        board_name_arr+=("${b_name:-}")
        servod_target_arr+=("${b_target:-}")
        servov4_sup_arr+=("${b_v4:-N}")
        c2d2_sup_arr+=("${b_c2d2:-N}")
        servo_micro_sup_arr+=("${b_micro:-N}")
        suzyqable_sup_arr+=("${b_suzy:-N}")
    done
}

list_support_board() {
    echo
    echo "Support board list:"
    echo
    printf "  %-3s | %-14s | %s\n" "N" "Board Name" "Servod Command"
    echo "------+----------------+------------------------------------------------------"
    local i
    for ((i=1; i<${#board_name_arr[@]}; i++)); do
        printf "  %2d  | %-14s | start-servod --channel=release -p 9999 -b %s\n" \
            "$i" "${board_name_arr[i]}" "${servod_target_arr[i]}"
    done
    echo
}

# ------------------------------------------------------------------------------
# Script Auto-Update
# ------------------------------------------------------------------------------
update_script() {
    local target_script=""
    if [[ "$0" -ef "$HOME/console_tool_v2.sh" || "$0" -ef "$HOME/workspace/console_tool_v2.sh" ]]; then
        target_script="$0"
    elif [[ -f "$HOME/workspace/console_tool_v2.sh" ]]; then
        target_script="$HOME/workspace/console_tool_v2.sh"
    elif [[ -f "$HOME/console_tool_v2.sh" ]]; then
        target_script="$HOME/console_tool_v2.sh"
    elif [[ -f "$0" ]]; then
        target_script="$0"
    else
        target_script="$HOME/workspace/console_tool_v2.sh"
    fi

    LOG "Starting script update..."
    local tmp_file
    tmp_file=$(mktemp /tmp/console_tool_v2.XXXXXX)

    LOG "Downloading script from $DOWNLOAD_URL..."
    if ! wget -q --show-progress "$DOWNLOAD_URL" -O "$tmp_file"; then
        LOG_E "Download failed!"
        rm -f "$tmp_file"
        exit 1
    fi

    mkdir -p "$(dirname "$target_script")"
    cp "$tmp_file" "$target_script"
    chmod a+x "$target_script"
    rm -f "$tmp_file"

    LOG "Script updated successfully to $target_script"
    exit 0
}

# ------------------------------------------------------------------------------
# ADB Connection
# ------------------------------------------------------------------------------
link_adb() {
    if ! command -v adb &>/dev/null; then
        LOG_W "Android Debug Bridge (adb) not found!"
        LOG "Starting auto-installation of adb..."
        sudo apt update && sudo apt install -y adb
        if ! command -v adb &>/dev/null; then
            LOG_E "adb installation failed!"
            exit 1
        fi
        LOG "adb installed successfully."
    else
        LOG "adb is ready."
    fi

    if [[ -z "$ADB_IP" ]]; then
        LOG_W "ADB_IP is not defined in $BOARD_LIST"
        read -r -p "Please input DUT IP: " ADB_IP
    fi

    if ping -c 1 -W 2 "$ADB_IP" &>/dev/null; then
        LOG "DUT ($ADB_IP) is online!"
    else
        LOG_W "DUT ($ADB_IP) is offline or not responding to ping."
        read -r -p "Press Enter to try connecting anyway..." _
    fi

    if ! adb devices | grep -q "$ADB_IP"; then
        LOG_C adb connect "$ADB_IP"
    fi

    LOG "Use [Ctrl]+[D] or type 'exit' to leave adb shell."
    LOG_C adb shell
}

# ------------------------------------------------------------------------------
# Pre-Flight Checks
# ------------------------------------------------------------------------------
check_chroot() {
    local chroot_file="/etc/cros_chroot_version"
    if [[ -e "$chroot_file" ]]; then
        LOG_E "Script is running INSIDE ChromeOS chroot!"
        echo "        Please run this script outside of chroot."
        exit_script -t 1
    fi
    LOG "Script is running outside of chroot."
}

check_term_tool() {
    local tool="$1"
    if ! command -v "$tool" &>/dev/null; then
        LOG_W "Console tool \"$tool\" not found."
        LOG "Starting auto-installation of $tool..."
        sudo apt update && sudo apt install -y "$tool"
        if ! command -v "$tool" &>/dev/null; then
            LOG_E "$tool installation failed!"
            exit 1
        fi
        LOG "$tool installed successfully."
    else
        LOG "$tool is ready."
    fi
}

check_servo_hardware() {
    # Probe USB devices once
    local usb_list
    usb_list=$(lsusb 2>/dev/null || true)

    have_ServoV2=$(grep -E '18d1:5002' <<< "$usb_list" || true)
    have_Servo_micro=$(grep -E '18d1:501a' <<< "$usb_list" || true)
    have_ServoV4=$(grep -E '18d1:501b' <<< "$usb_list" || true)
    have_ServoV4p1=$(grep -E '18d1:520d' <<< "$usb_list" || true)
    have_SuzyQable=$(grep -E '18d1:501f' <<< "$usb_list" || true)
    have_C2D2=$(grep -E '18d1:5041' <<< "$usb_list" || true)
    have_Cr50=$(grep -E '18d1:5014' <<< "$usb_list" || true)
    have_Ti50v1=$(grep -E '18d1:504a' <<< "$usb_list" || true)
    have_Ti50v2=$(grep -E '18d1:5066' <<< "$usb_list" || true)

    have_Ti50="${have_Ti50v1}${have_Ti50v2}"
    have_CCD="${have_Cr50}${have_Ti50}"
    have_Servo_type_c="${have_ServoV4}${have_ServoV4p1}${have_SuzyQable}"
    have_Servo_connector="${have_ServoV2}${have_Servo_micro}${have_C2D2}"

    # If no servo device found at all
    if [[ -z "$have_Servo_type_c" && -z "$have_Servo_connector" && -z "$have_CCD" ]]; then
        LOG_E "Cannot find any servo board connected!"
        LOG_C lsusb
        echo
        echo "Please connect a servo board and try again."
        exit_script 1
    fi

    # Set boolean flags
    useServoV2=false
    useServoV4=false
    useServoV4p1=false
    useServo_micro=false
    useSuzyQable=false
    useC2D2=false
    useCCD=false

    [[ -n "$have_ServoV2" ]]      && { LOG "Found USB device: ServoV2"; useServoV2=true; }
    [[ -n "$have_ServoV4" ]]      && { LOG "Found USB device: ServoV4"; useServoV4=true; }
    [[ -n "$have_ServoV4p1" ]]    && { LOG "Found USB device: ServoV4p1"; useServoV4p1=true; useServoV4=true; }
    [[ -n "$have_SuzyQable" ]]    && { LOG "Found USB device: SuzyQable"; useSuzyQable=true; }
    [[ -n "$have_Servo_micro" ]]  && { LOG "Found USB device: Servo_micro"; useServo_micro=true; }
    [[ -n "$have_C2D2" ]]         && { LOG "Found USB device: C2D2"; useC2D2=true; }
    [[ -n "$have_Cr50" ]]         && { LOG "Found USB device: Cr50"; useCCD=true; }
    [[ -n "$have_Ti50" ]]         && { LOG "Found USB device: Ti50"; useCCD=true; }

    # Validate combination
    local invalid_combo=false
    if [[ -n "$have_SuzyQable" && -n "$have_ServoV4" ]] || \
       [[ -n "$have_SuzyQable" && -n "$have_ServoV4p1" ]] || \
       [[ -n "$have_ServoV4" && -n "$have_ServoV4p1" ]] || \
       [[ -n "$have_Servo_micro" && -n "$have_C2D2" ]] || \
       [[ -n "$have_Cr50" && -n "$have_Ti50" ]]; then
        invalid_combo=true
    fi

    if $invalid_combo; then
        LOG_W "Unknown / Conflicting Servo Board Combination Detected:"
        echo "        ServoV2     : ${have_ServoV2:-None}"
        echo "        ServoV4     : ${have_ServoV4:-None}"
        echo "        ServoV4p1   : ${have_ServoV4p1:-None}"
        echo "        SuzyQable   : ${have_SuzyQable:-None}"
        echo "        Servo_micro : ${have_Servo_micro:-None}"
        echo "        C2D2        : ${have_C2D2:-None}"
        echo "        Cr50        : ${have_Cr50:-None}"
        echo "        Ti50        : ${have_Ti50:-None}"
        echo
        echo "        Please ensure servo board connection is correct."
        read -r -p "Press Enter to continue anyway... " _
    elif [[ -n "$have_Servo_type_c" && -z "$have_CCD" ]]; then
        if [[ -n "$have_SuzyQable" ]]; then
            LOG_W "Found SuzyQable but CCD was not found."
            LOG_W "Please flip SuzyQable connector or try another USB Type-C port on the DUT!"
        else
            LOG_W "Found Type-C servo board, but CCD was not detected."
        fi
        echo "        Please check if the servo board is connected to the CCD-enabled port."
        echo
        LOG_W "Current 18d1 USB devices:"
        grep -E '18d1' <<< "$usb_list" || true
        echo
        read -r -p "Press Enter to continue... " _
    else
        LOG "Servo board combination is correct."
    fi
}

is_servod_running() {
    # 1. Quick check using bash built-in TCP socket
    if (echo > /dev/tcp/127.0.0.1/9999) 2>/dev/null; then
        return 0
    fi
    # 2. Check if port 9999 is actively listening via ss
    if ss -tln 2>/dev/null | grep -E ':(9999)\b' &>/dev/null; then
        return 0
    fi
    # 3. Fallback to lsof
    if sudo lsof -i -P -n -w 2>/dev/null | grep -E ':(9999)\b' &>/dev/null; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# Servod Launcher
# ------------------------------------------------------------------------------
start_servod_session() {
    if [[ -n "$target_port" ]]; then
        LOG_W "servod is not currently running!"
    fi

    # If board not selected via CLI, prompt user
    if [[ -z "$selected_board_idx" ]]; then
        list_support_board
        read -r -p "Target Board number: " selected_board_idx
    fi

    # Validate numeric input
    if ! [[ "$selected_board_idx" =~ ^[0-9]+$ ]]; then
        LOG_E "Invalid input! Board number must be an integer."
        exit_script -t 1
    fi

    if [[ "$selected_board_idx" -eq 0 ]]; then
        exit_script 0
    fi

    if [[ "$selected_board_idx" -ge "${#board_name_arr[@]}" ]]; then
        LOG_E "Board number $selected_board_idx is out of range!"
        exit_script -t 1
    fi

    local board_name="${board_name_arr[$selected_board_idx]}"
    local servod_target="${servod_target_arr[$selected_board_idx]}"

    # Hardware compatibility checks
    if $useServoV4 && [[ "${servov4_sup_arr[$selected_board_idx]}" != "Y" ]]; then
        LOG_E "$board_name does not support ServoV4!"
        exit_script -t 1
    fi
    if $useC2D2 && [[ "${c2d2_sup_arr[$selected_board_idx]}" != "Y" ]]; then
        LOG_E "$board_name does not support C2D2!"
        exit_script -t 1
    fi
    if $useServo_micro && [[ "${servo_micro_sup_arr[$selected_board_idx]}" != "Y" ]]; then
        LOG_E "$board_name does not support Servo_micro!"
        exit_script -t 1
    fi
    if $useSuzyQable && [[ "${suzyqable_sup_arr[$selected_board_idx]}" != "Y" ]]; then
        LOG_E "$board_name does not support SuzyQable!"
        exit_script -t 1
    fi

    local servod_args="-f=INFO --allow_offline"
    LOG "Starting servod for board '$board_name' ($servod_target)..."
    LOG_EVAL "start-servod --channel=$channel -p 9999 $servod_args -b $servod_target"
    exit_script 0
}

# ------------------------------------------------------------------------------
# Console Port Connection
# ------------------------------------------------------------------------------
get_pty_port() {
    local control_name="$1"
    local raw_out pts_path

    raw_out=$(dut-control -- "$control_name" 2>/dev/null || true)
    pts_path=$(echo "$raw_out" | grep -oE '/dev/pts/[0-9]+' | head -n 1)
    if [[ -z "$pts_path" ]]; then
        pts_path=$(echo "$raw_out" | awk -F': ' '{print $2}' | tr -d '\r\n ')
    fi

    if [[ -z "$pts_path" || ! "$pts_path" =~ ^/dev/pts/[0-9]+$ ]]; then
        return 1
    fi

    echo "$pts_path"
    return 0
}

open_console_port() {
    local port="$1"
    local label="$2"

    LOG "Opening $label console on port $port..."

    if $use_minicom; then
        LOG "Exit minicom keybinding: [Ctrl]+[A] > [Q] (or [X]) > [Enter]"
    else
        LOG "Exit picocom keybinding: [Ctrl]+[A] > [Ctrl]+[X]"
    fi

    if $save_log; then
        local now
        now=$(date +"%Y-%m-%d_%H-%M-%S")
        local log_file="log_${label}_${now}.txt"
        LOG "Session log will be saved to ~/$log_file"

        if $use_minicom; then
            LOG_C sudo minicom -D "$port" -C "$HOME/$log_file"
        else
            LOG_C sudo picocom "$port" -g "$HOME/$log_file"
            # Strip ANSI escape sequences from captured log
            if [[ -f "$HOME/$log_file" ]]; then
                sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$HOME/$log_file" > "$HOME/${log_file}.clean"
                mv "$HOME/${log_file}.clean" "$HOME/$log_file"
            fi
        fi
    else
        if $use_minicom; then
            LOG_C sudo minicom -D "$port"
        else
            LOG_C sudo picocom "$port"
        fi
    fi

    exit_script 0
}

connect_target_port() {
    local target="$1"
    local port=""

    case "$target" in
        ec|EC)
            port=$(get_pty_port "ec_uart_pty") || {
                LOG_E "dut-control failed to obtain EC port (ec_uart_pty)"
                exit_script -t 1
            }
            open_console_port "$port" "ec"
            ;;
        gsc|GSC|ccd|CCD|cr50|CR50|ti50|TI50|h1|H1)
            port=$(get_pty_port "gsc_uart_pty") || port=$(get_pty_port "cr50_uart_pty") || {
                LOG_E "dut-control failed to obtain GSC port (gsc_uart_pty / cr50_uart_pty)"
                exit_script -t 1
            }
            open_console_port "$port" "gsc"
            ;;
        bios|BIOS|cpu|CPU|ap|AP)
            port=$(get_pty_port "cpu_uart_pty") || {
                LOG_E "dut-control failed to obtain CPU/AP port (cpu_uart_pty)"
                exit_script -t 1
            }
            open_console_port "$port" "bios"
            ;;
        v4|V4|servo_v4|servo_v4p1)
            if $useServoV4p1; then
                port=$(get_pty_port "servo_v4p1_uart_pty") || {
                    LOG_E "dut-control failed to obtain ServoV4p1 port (servo_v4p1_uart_pty)"
                    exit_script -t 1
                }
                open_console_port "$port" "servo_v4p1"
            elif $useServoV4; then
                port=$(get_pty_port "servo_v4_uart_pty") || {
                    LOG_E "dut-control failed to obtain ServoV4 port (servo_v4_uart_pty)"
                    exit_script -t 1
                }
                open_console_port "$port" "servo_v4"
            else
                LOG_E "No ServoV4 or ServoV4p1 hardware detected!"
                exit_script -t 1
            fi
            ;;
        *)
            LOG_E "Unknown target: $target"
            exit_script -t 1
            ;;
    esac
}

prompt_target_menu() {
    echo
    LOG "Choose which console port you want to open:"
    echo "        [0] Exit"
    echo "        [1] Open EC console"
    echo "        [2] Open GSC / CCD console"
    echo "        [3] Open BIOS / AP console"
    echo "        [4] Open Servo_V4 / V4p1 console"
    echo

    local choice
    read -r -p "Connect Port [0-4]: " choice
    case "$choice" in
        0) exit_script 0 ;;
        1) connect_target_port "ec" ;;
        2) connect_target_port "gsc" ;;
        3) connect_target_port "bios" ;;
        4) connect_target_port "servo_v4" ;;
        *)
            LOG_E "Invalid option: $choice"
            exit_script -t 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Channel Selection
# ------------------------------------------------------------------------------
select_channel_interactive() {
    LOG "Channel selection:"
    LOG "  [0] release (default)"
    LOG "  [1] local"
    LOG "  [2] latest"
    LOG "  [3] beta"
    local ch_choice
    read -r -p "Select channel [0-3]: " ch_choice
    case "$ch_choice" in
        0|"") channel="release" ;;
        1) channel="local" ;;
        2) channel="latest" ;;
        3) channel="beta" ;;
        *)
            LOG_E "Invalid channel selection!"
            exit_script -t 1
            ;;
    esac
}

# ------------------------------------------------------------------------------
# Main Entry Point
# ------------------------------------------------------------------------------
main() {
    echo
    LOG "Console Tool v2"
    LOG "Original Author: Yu-An Chen | Version: $SCRIPT_VERSION (Modified: $LAST_MODIFIED)"

    # Operational flags
    channel="release"
    channel_interactive=false
    use_minicom=false
    save_log=false
    debug_mode="Disable"

    selected_board_idx=""
    target_port=""

    # First load configured board list so we can recognize board arguments
    load_board_list

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help|help)
                show_help
                exit 0
                ;;
            -v|-V|--version)
                echo "Console Tool v$SCRIPT_VERSION ($LAST_MODIFIED)"
                exit 0
                ;;
            -l|--list|--list_board)
                list_support_board
                exit 0
                ;;
            -u|--update)
                update_script
                ;;
            adb|host|--adb|--host)
                link_adb
                exit 0
                ;;
            -c|--channel)
                if [[ -n "$2" && "$2" != -* && "$2" =~ ^(release|local|latest|beta)$ ]]; then
                    channel="$2"
                    shift
                else
                    channel_interactive=true
                fi
                ;;
            --channel=*)
                channel="${1#*=}"
                ;;
            -m|--minicom)
                use_minicom=true
                ;;
            -r|--record|--log)
                save_log=true
                ;;
            --debug)
                debug_mode="Enable"
                ;;
            ec|EC|--ec)
                target_port="ec"
                LOG "Target port: EC"
                ;;
            bios|BIOS|cpu|CPU|ap|AP|--bios|--cpu|--ap)
                target_port="bios"
                LOG "Target port: BIOS/AP"
                ;;
            ccd|CCD|cr50|CR50|ti50|TI50|h1|H1|gsc|GSC|--ccd|--cr50|--ti50|--h1|--gsc)
                target_port="gsc"
                LOG "Target port: GSC/CCD"
                ;;
            v4|V4|--v4|servo_v4|servo_v4p1)
                target_port="servo_v4"
                LOG "Target port: Servo_V4"
                ;;
            *)
                # Check if argument matches a known board name
                local found_board=false
                local idx
                for ((idx=1; idx<${#board_name_arr[@]}; idx++)); do
                    if [[ "$1" == "${board_name_arr[idx]}" ]]; then
                        selected_board_idx="$idx"
                        LOG "Target board selected: $1 (index $idx)"
                        found_board=true
                        break
                    fi
                done

                if ! $found_board; then
                    LOG_W "Unknown argument: $1"
                fi
                ;;
        esac
        shift
    done

    # Interactive channel selection if requested
    if $channel_interactive; then
        select_channel_interactive
    fi
    LOG "Channel: $channel"

    # Run pre-flight checks
    check_chroot

    if $use_minicom; then
        check_term_tool "minicom"
    else
        check_term_tool "picocom"
    fi

    check_servo_hardware

    # Check if servod daemon is running
    if ! is_servod_running; then
        start_servod_session
    else
        LOG "docker servod is ready"
        LOG "Use 'stop-servod' to shutdown servod when finished."
    fi

    # Connect to console port
    if [[ -n "$target_port" ]]; then
        connect_target_port "$target_port"
    else
        prompt_target_menu
    fi

    exit_script 0
}

main "$@"
