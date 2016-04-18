#!/usr/bin/env bash
export DOLLAR='$'

BACKUP_DIR='backup'
if [ ! -d "$BACKUP_DIR" ]; then
    mkdir $BACKUP_DIR
fi

echo "Begin to loading configuration."
source config.sh
echo "Finish laoding configuration."

echo "Begin to install freeradius."
# yum update -y
yum install freeradius -y > /dev/null
echo "Finish installing freeradius."

## eduroam
echo "Begin to set $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam."
rm -f $RADIUS_MAIN_DIR/sites-enabled/default
envsubst < templates/eduroam > $RADIUS_MAIN_DIR/sites-available/eduroam
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam $RADIUS_MAIN_DIR/sites-enabled/eduroam
echo "Finish setting $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam."

## pre-proxy
echo "Begin to set $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy."
if [ ! -f $BACKUP_DIR/pre-proxy ]; then
    cp $RADIUS_MAIN_DIR/mods-config-attr_filter/pre-proxy $BACKUP_DIR/pre-proxy
fi
sed -i '${s/$/,\n\tCalling-Station-Id =* ANY,\n\tCalled-Station-Id =* ANY,\n\tOperator-Name =* ANY/}' $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy
echo "Finish setting $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy."

## clients.conf
echo "Begin to set $RADIUS_MAIN_DIR/clients.conf."
if [ ! -f $BACKUP_DIR/clients.conf ]; then
    cp $RADIUS_MAIN_DIR/clients.conf $BACKUP_DIR/clients.conf
else
    mv -f $BACKUP_DIR/clients.conf $RADIUS_MAIN_DIR/clients.conf
fi
envsubst < templates/clients.conf >> $RADIUS_MAIN_DIR/clients.conf
echo "Finish setting $RADIUS_MAIN_DIR/clients.conf."

## proxy.conf
echo "Begin to set $RADIUS_MAIN_DIR/proxy.conf."
if [ ! -f $BACKUP_DIR/proxy.conf ]; then
    cp $RADIUS_MAIN_DIR/proxy.conf $BACKUP_DIR/proxy.conf
else
    mv -f $BACKUP_DIR/proxy.conf $RADIUS_MAIN_DIR/proxy.conf
fi
envsubst < templates/proxy.conf >> $RADIUS_MAIN_DIR/proxy.conf
echo "Finish setting $RADIUS_MAIN_DIR/proxy.conf."

## eap
echo "Begin to set $RADIUS_MAIN_DIR/mods-[available|enabled]/eap"
sh $RADIUS_MAIN_DIR/certs/bootstrap > /dev/null
if [ ! -f $BACKUP_DIR/eap ]; then
    cp $RADIUS_MAIN_DIR/mods-available/eap $BACKUP_DIR/eap
fi
envsubst < templates/eap > $RADIUS_MAIN_DIR/mods-available/eap
ln -sf $RADIUS_MAIN_DIR/mods-available/eap $RADIUS_MAIN_DIR/mods-enabled/eap
echo "Finish setting $RADIUS_MAIN_DIR/mods-[available|enabled]/eap"

## eduroam-inner-tunnel
echo "Begin to set $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam-inner-tunnel."
rm -f $RADIUS_MAIN_DIR/sites-enabled/inner-tunnel
envsubst < templates/eduroam-inner-tunnel > $RADIUS_MAIN_DIR/sites-available/eduroam-inner-tunnel
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam-inner-tunnel $RADIUS_MAIN_DIR/sites-enabled/eduroam-inner-tunnel
echo "Finish setting $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam-inner-tunnel."

## users
echo "Begin to set $RADIUS_MAIN_DIR/users."
rm -f $RADIUS_MAIN_DIR/users
envsubst < templates/users > $RADIUS_MAIN_DIR/users
echo "Finish setting $RADIUS_MAIN_DIR/users."
