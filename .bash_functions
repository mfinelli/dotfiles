# vim: ft=sh

# prepare the computer for going abroad
function volo {
    # timedatectl set-timezone basically just creates a symbolic link from
    # /usr/share/zoneinfo/... to /etc/localtime

    case "$1"
        usa )
            sudo timedatectl set-timezone America/New_York
            ;;
        uk )
            sudo timedatectl set-timezone Europe/London
            ;;
        italy )
            sudo timedatectl set-timezone Europe/Rome
            ;;
        * )
            echo "Not doing anything..."
    esac
}
