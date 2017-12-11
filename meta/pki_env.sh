export PKI_HOME=${PARCELS_ROOT}/$PARCEL_DIRNAME

PKI_ENABLED=false
if [ -f pki-conf/init.sh ]; then
    . pki-conf/init.sh
    PKI_ENABLED=true
fi
export PKI_ENABLED
