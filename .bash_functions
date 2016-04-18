# vim: ft=sh

# prepare the computer for going abroad
function volo {
    # timedatectl set-timezone basically just creates a symbolic link from
    # /usr/share/zoneinfo/... to /etc/localtime

    case "$1" in
        usa )
            sudo timedatectl set-timezone America/New_York

            # comment out other countries
            for country in IT GB; do
                sudo sed -i "/^WIRELESS_REGDOM=\"$country\"/s/^/#/" \
                    /etc/conf.d/wireless-regdom
            done

            # uncomment US
            sudo sed -i '/WIRELESS_REGDOM="US"/s/^#//' \
                /etc/conf.d/wireless-regdom
            ;;
        uk )
            sudo timedatectl set-timezone Europe/London

            # comment out other countries
            for country in IT US; do
                sudo sed -i "/^WIRELESS_REGDOM=\"$country\"/s/^/#/" \
                    /etc/conf.d/wireless-regdom
            done

            # uncomment GB
            sudo sed -i '/WIRELESS_REGDOM="GB"/s/^#//' \
                /etc/conf.d/wireless-regdom
            ;;
        italy )
            sudo timedatectl set-timezone Europe/Rome

            # comment out other countries
            for country in GB US; do
                sudo sed -i "/^WIRELESS_REGDOM=\"$country\"/s/^/#/" \
                    /etc/conf.d/wireless-regdom
            done

            # uncomment IT
            sudo sed -i '/WIRELESS_REGDOM="IT"/s/^#//' \
                /etc/conf.d/wireless-regdom
            ;;
        * )
            echo "Not doing anything..."
    esac
}

function mmrb {
    case "$1" in
        start)
            sudo systemctl start mysqld
            sudo systemctl start redis
            sudo systemctl start memcached
            sudo systemctl start beanstalkd
            ;;
        stop)
            sudo systemctl stop mysqld
            sudo systemctl stop redis
            sudo systemctl stop memcached
            sudo systemctl stop beanstalkd
            ;;
        *)
            echo "Start or stop...?"
            return 1
            ;;
    esac
}
