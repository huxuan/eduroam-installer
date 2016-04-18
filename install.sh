#!/usr/bin/env bash
source config.sh
export DOLLAR='$'

# yum update -y
yum install freeradius -y > /dev/null

## eduroam
#TODO(huxuan): Backup before remove
rm -f $RADIUS_MAIN_DIR/sites-enabled/default
envsubst < templates/eduroam > $RADIUS_MAIN_DIR/sites-available/eduroam
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam $RADIUS_MAIN_DIR/sites-enabled/eduroam

## pre-proxy
sed -i '${s/$/,\n\tCalling-Station-Id =* ANY,\n\tCalled-Station-Id =* ANY,\n\tOperator-Name =* ANY/}' etc/raddb/mods-config/attr_filter/pre-proxy

## clients.conf
envsubst < templates/clients.conf >> $RADIUS_MAIN_DIR/clients.conf

## proxy.conf
envsubst < templates/proxy.conf >> $RADIUS_MAIN_DIR/proxy.conf

## eap
sh $RADIUS_MAIN_DIR/certs/bootstrap > /dev/null
envsubst < templates/eap > $RADIUS_MAIN_DIR/mods-available/eap
ln -sf $RADIUS_MAIN_DIR/mods-available/eap $RADIUS_MAIN_DIR/mods-enabled/eap

## eduroam-inner-tunnel
rm -f $RADIUS_MAIN_DIR/sites-enabled/inner-tunnel
envsubst < templates/eduroam-inner-tunnel > $RADIUS_MAIN_DIR/sites-available/eduroam-inner-tunnel
ln -sf $RADIUS_MAIN_DIR/sites-available/eduroam-inner-tunnel $RADIUS_MAIN_DIR/sites-enabled/eduroam-inner-tunnel

## users
rm -f $RADIUS_MAIN_DIR/users
envsubst < templates/users > $RADIUS_MAIN_DIR/users
