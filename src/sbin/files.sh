#!/bin/bash

echo ""
echo "Oracle XE 11g CI/Development image"
echo "By Rodrigo Hiemer, 2021 - https://github.com/rhiemer"
echo ""
echo "https://github.com/rhiemer/docker-oracle-xe-11g"
echo "forked from epiclabs/docker-oracle-xe-11g - https://github.com/epiclabs-io/docker-oracle-xe-11g"
echo ""
echo ""

 
source $HOME/.bashrc


LISTENER_ORA=/u01/app/oracle-product/11.2.0/xe/network/admin/listener.ora
TNSNAMES_ORA=/u01/app/oracle-product/11.2.0/xe/network/admin/tnsnames.ora

cp "${LISTENER_ORA}.tmpl" "$LISTENER_ORA" &&
sed -i "s/%hostname%/$HOSTNAME/g" "${LISTENER_ORA}" &&
sed -i "s/%port%/1521/g" "${LISTENER_ORA}" &&
cp "${TNSNAMES_ORA}.tmpl" "$TNSNAMES_ORA" &&
sed -i "s/%hostname%/$HOSTNAME/g" "${TNSNAMES_ORA}" &&
sed -i "s/%port%/1521/g" "${TNSNAMES_ORA}" &&


rm -rf /u01/app/oracle/product

ln -sfv /u01/app/oracle-product /u01/app/oracle/product    #Mount database installation to the Expanded VOLUME of container

if [ ! -d /u01/app/oracle/dbs ] ; then
	echo "using default configuration"
	tar xf /u01/app/default-dbs.tar.gz -C /u01/app/oracle/
fi

if [ ! -d /u01/app/oracle/oradata ] ; then
	echo "using default data directory"
	tar xf /u01/app/default-oradata.tar.gz
fi

if [ ! -d /u01/app/oracle/admin ] ; then
	echo "using default admin directory"
	tar xf /u01/app/default-admin.tar.gz
fi

if [ ! -d /u01/app/oracle/fast_recovery_area ] ; then
	echo "using default fast_recovery_area directory"
	tar xf /u01/app/default-fast_recovery_area.tar.gz
fi

ln -s /u01/app/oracle/dbs /u01/app/oracle-product/11.2.0/xe/dbs    #Link db configuration to the installation path form extended volume with DB data

chown -R oracle:dba /u01/app/oracle