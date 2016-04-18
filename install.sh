#!/usr/bin/env bash
echo "Begin to loading configuration."
source config.sh
export DOLLAR='$'
echo "Finish laoding configuration."

echo "Begin to install freeradius."
# yum update -y
yum install freeradius -y > /dev/null
echo "Finish installing freeradius."

## eduroam
#TODO(huxuan): Backup before remove
echo "Begin to set $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam."
rm -f $RADIUS_MAIN_DIR/sites-enabled/default
envsubst < templates/eduroam > $RADIUS_MAIN_DIR/sites-available/eduroam
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam $RADIUS_MAIN_DIR/sites-enabled/eduroam
echo "Finish setting $RADIUS_MAIN_DIR/sites-[available|enabled]/eduroam."

## pre-proxy
echo "Begin to set $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy."
sed -i '${s/$/,\n\tCalling-Station-Id =* ANY,\n\tCalled-Station-Id =* ANY,\n\tOperator-Name =* ANY/}' etc/raddb/mods-config/attr_filter/pre-proxy
echo "Finish setting $RADIUS_MAIN_DIR/mods-config/attr_filter/pre-proxy."

## clients.conf
echo "Begin to set $RADIUS_MAIN_DIR/clients.conf."
envsubst < templates/clients.conf >> $RADIUS_MAIN_DIR/clients.conf
echo "Finish setting $RADIUS_MAIN_DIR/clients.conf."

## proxy.conf
echo "Begin to set $RADIUS_MAIN_DIR/proxy.conf."
envsubst < templates/proxy.conf >> $RADIUS_MAIN_DIR/proxy.conf
echo "Finish setting $RADIUS_MAIN_DIR/proxy.conf."

## eap
echo "Begin to set $RADIUS_MAIN_DIR/mods-[available|enabled]/eap"
sh $RADIUS_MAIN_DIR/certs/bootstrap > /dev/null
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
