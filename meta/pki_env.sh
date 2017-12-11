export PKI_ENABLED="true"
export PKI_HOME=${PARCELS_ROOT}/$PARCEL_DIRNAME

if [ -f pki-conf/init.sh ]; then
    . pki-conf/init.sh
fi
