#!/usr/bin/env bash

## shared variable and function
export DOLLAR='$'
export RADIUS_MAIN_DIR="/etc/raddb"
function generate_random_password {
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16;
}

## check prerequirements
# Only support Linux currently.
if [[ `uname` != 'Linux' ]]; then
    echo '==> platform not supported, aborting'
    exit 1
fi
# Get distribution and version.
if [[ -r /etc/os-release ]]; then
    # this will get the required information without dirtying any env state
    DIST_VERS="$( ( . /etc/os-release &>/dev/null
                    echo "$ID $VERSION_ID") )"
    DISTRO="${DIST_VERS%% *}" # get our distro name
    VERSION="${DIST_VERS##* }" # get our version number
elif [[ -r /etc/redhat-release ]]; then
    DIST_VERS=( $( cat /etc/redhat-release ) ) # make the file an array
    DISTRO="${DIST_VERS[0],,}" # get the first element and get lcase
    VERSION="${DIST_VERS[2]}" # get the third element (version)
elif [[ -r /etc/lsb-release ]]; then
    DIST_VERS="$( ( . /etc/lsb-release &>/dev/null
                    echo "${DISTRIB_ID,,} $DISTRIB_RELEASE") )"
    DISTRO="${DIST_VERS%% *}" # get our distro name
    VERSION="${DIST_VERS##* }" # get our version number
else # well, I'm out of ideas for now
    echo '==> Failed to determine distro and version.'
    exit 1
fi
# Set up backup folder.
BACKUP_DIR='backup'
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir $BACKUP_DIR
fi

echo "Loading configuration."
source config.sh

# Install freeradius based on specific distribution and version
echo "Installing freeradius."
DISTRO_VERSION_MSG="[Info] $DISTRO $VERSION detected."
DISTRO_VERSION_WARNING_MSG="[Warning] $DISTRO $VERSION is not fully supported. Try to install from source but no success guarantee."
if [ "$DISTRO" == "centos" ] && [ "$VERSION" == 7 ]; then
    echo $DISTRO_VERSION_MSG
    export RADIUS_MAIN_DIR="/etc/raddb"
    # yum update -y
    yum install freeradius -y > /dev/null
elif [ "$DISTRO" == "centos" ]; then
    echo $DISTRO_VERSION_WARNING_MSG
    export RADIUS_MAIN_DIR="/usr/local/etc/raddb"
    yum install gcc libtalloc-devel openssl-devel -y
    if [ ! -f freeradius-server-3.0.11.tar.gz ]; then
        wget ftp://ftp.freeradius.org/pub/freeradius/freeradius-server-3.0.11.tar.gz
    fi
    tar -zxvf freeradius-server-3.0.11.tar.gz
    cd freeradius-server-3.0.11 && ./configure && make && make install
    cd ..
else
    echo "==> $DISTRO $VERSION is not supported, aborting"
    exit 1
fi

## eduroam
echo "Setting $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam."
rm -f $RADIUS_MAIN_DIR/sites-enabled/default
envsubst < templates/eduroam > $RADIUS_MAIN_DIR/sites-available/eduroam
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam $RADIUS_MAIN_DIR/sites-enabled/eduroam

## pre-proxy
echo "Setting $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy."
if [ ! -f $BACKUP_DIR/pre-proxy ]; then
    cp $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy $BACKUP_DIR/pre-proxy
fi
sed -i '${s/$/,\n\tCalling-Station-Id =* ANY,\n\tCalled-Station-Id =* ANY,\n\tOperator-Name =* ANY/}' $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy

## clients.conf
echo "Setting $RADIUS_MAIN_DIR/clients.conf."
if [ ! -f $BACKUP_DIR/clients.conf ]; then
    cp $RADIUS_MAIN_DIR/clients.conf $BACKUP_DIR/clients.conf
else
    cp -f $BACKUP_DIR/clients.conf $RADIUS_MAIN_DIR/clients.conf
fi
envsubst < templates/clients.conf >> $RADIUS_MAIN_DIR/clients.conf

## proxy.conf
echo "Setting $RADIUS_MAIN_DIR/proxy.conf."
if [ ! -f $BACKUP_DIR/proxy.conf ]; then
    cp $RADIUS_MAIN_DIR/proxy.conf $BACKUP_DIR/proxy.conf
else
    cp -f $BACKUP_DIR/proxy.conf $RADIUS_MAIN_DIR/proxy.conf
fi
for IDX in "${!PARENT_IP_ADDRESSES[@]}"; do
    export IDX
    export IP_ADDRESS=${PARENT_IP_ADDRESSES[$IDX]}
    export SECRET=$(generate_random_password)
    PARENT_SECRETS[$IDX]=$SECRET
    envsubst < templates/proxy.home_server.conf >> $RADIUS_MAIN_DIR/proxy.conf
done
envsubst < templates/proxy.home_server_pool.header.conf >> $RADIUS_MAIN_DIR/proxy.conf
for IDX in "${!PARENT_IP_ADDRESSES[@]}"; do
    export IDX
    envsubst < templates/proxy.home_server_pool.body.conf >> $RADIUS_MAIN_DIR/proxy.conf
done
envsubst < templates/proxy.home_server_pool.footer.conf >> $RADIUS_MAIN_DIR/proxy.conf

## eap
echo "Setting $RADIUS_MAIN_DIR/mods-[available|enabled]/eap"
sh $RADIUS_MAIN_DIR/certs/bootstrap > /dev/null
if [ ! -f $BACKUP_DIR/eap ]; then
    cp $RADIUS_MAIN_DIR/mods-available/eap $BACKUP_DIR/eap
fi
envsubst < templates/eap > $RADIUS_MAIN_DIR/mods-available/eap
ln -sf $RADIUS_MAIN_DIR/mods-available/eap $RADIUS_MAIN_DIR/mods-enabled/eap

## eduroam-inner-tunnel
echo "Setting $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam-inner-tunnel."
rm -f $RADIUS_MAIN_DIR/sites-enabled/inner-tunnel
envsubst < templates/eduroam-inner-tunnel > $RADIUS_MAIN_DIR/sites-available/eduroam-inner-tunnel
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam-inner-tunnel $RADIUS_MAIN_DIR/sites-enabled/eduroam-inner-tunnel

## users
echo "Setting $RADIUS_MAIN_DIR/users."
rm -f $RADIUS_MAIN_DIR/users
envsubst < templates/users > $RADIUS_MAIN_DIR/users

echo "Finish installing eduroam."
echo "List of upstream eduroam server IP address and corresponding secret:"
for IDX in "${!PARENT_IP_ADDRESSES[@]}"; do
    echo -e "${PARENT_IP_ADDRESSES[$IDX]}\t${PARENT_SECRETS[$IDX]}"
done
