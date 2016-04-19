#!/usr/bin/env bash
export DOLLAR='$'
function generate_random_password {
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16;
}

BACKUP_DIR='backup'
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir $BACKUP_DIR
fi

echo "Loading configuration."
source config.sh

echo "Installing freeradius."
# yum update -y
yum install freeradius -y > /dev/null

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
