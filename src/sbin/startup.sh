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


echo "Iniciando serviço oracle-xe"
service oracle-xe restart
echo "Status serviço oracle-xe"
service oracle-xe status