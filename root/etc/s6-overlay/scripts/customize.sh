#!/command/with-contenv bash

set -x

### Use environment variables to configure services

# If the first run completed successfully, we are done
if [ -e /.firstRunComplete ]; then
  exit 0

fi

# Make sure environment variables are set
if [ -z ${URL:-} ]; then
  echo "URL not set"
  exit 1

fi

# configure dashboard
if [ ! -z ${CALLSIGN:-} ]; then
  sed -i "s/\(PageOptions\['MetaAuthor'\][[:blank:]]*\=[[:blank:]]*\)'\([[:alnum:]]*\)'/\1\'${CALLSIGN}\'/g" ${URFD_DASH_CONFIG} # callsign

fi

if [ ! -z ${EMAIL:-} ]; then
  sed -i "s/\(PageOptions\['ContactEmail'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${EMAIL}\'/g" ${URFD_DASH_CONFIG} # email address

fi

sed -i "s/\(CallingHome\['Country'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${COUNTRY} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${URFD_DASH_CONFIG} # country
sed -i "s/\(CallingHome\['Comment'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"/\1\"$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')\"/g" ${URFD_DASH_CONFIG} # description
sed -i "s/\(CallingHome\['MyDashBoardURL'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'http:\/\/${URL}:${PORT}\/\'/g" ${URFD_DASH_CONFIG} # URL
sed -i "s/\(CallingHome\['Active'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${CALLHOME}/g" ${URFD_DASH_CONFIG} # call home active
sed -i "s/\(PageOptions\['NumberOfModules'\][[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${NUM_MODULES}/g" ${URFD_DASH_CONFIG} # number of modules
sed -i "s/\(PageOptions\['ModuleNames'\]\['A'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEA}\'/g" ${URFD_DASH_CONFIG} # name module A
sed -i "s/\(PageOptions\['ModuleNames'\]\['B'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEB}\'/g" ${URFD_DASH_CONFIG} # name module B
sed -i "s/\(PageOptions\['ModuleNames'\]\['C'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULEC}\'/g" ${URFD_DASH_CONFIG} # name module C
sed -i "s/\(PageOptions\['ModuleNames'\]\['D'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'${MODULED}\'/g" ${URFD_DASH_CONFIG} # name module D
sed -i "s/\(PageOptions\['RepeatersPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'HideIP\'/g" ${URFD_DASH_CONFIG} # Hide IP addresses on repeaters page
sed -i "s/\(PageOptions\['PeerPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1\'HideIP\'/g" ${URFD_DASH_CONFIG} # Hide IP addresses on peer page
sed -i "s/\(PageOptions\['CustomTXT'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'/\1'$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')'/g" ${URFD_DASH_CONFIG} # Add description text
sed -i "s/\(PageOptions\['IRCDDB'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1false/g" ${URFD_DASH_CONFIG} # Hide IRCDDB page
sed -i "/_GET\['show'\]\ ==\ \"livequadnet\"/d" ${URFD_WEB_DIR}/index.php # remove livequadnet
sed -i "/show=livequadnet/d" ${URFD_WEB_DIR}/index.php # remove livequadnet
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${URFD_WEB_DIR}/pgs/peers.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${URFD_WEB_DIR}/pgs/repeaters.php # convert date format to US
sed -i "s/d\.m\.Y/m\/d\/Y/g" ${URFD_WEB_DIR}/pgs/users.php # convert date format to US


# install configuration files
if [[ -e ${URFD_CONFIG_DIR:-} ]] && [[ -e ${URFD_CONFIG_TMP_DIR:-} ]]; then
  IP=$( hostname -I )
  sed -i "/\[Names\]/{n;s/\(Callsign[[:blank:]]*\=[[:blank:]]*\)URF[[:print:]]*/\1${URFNUM}/;}" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(SysopEmail[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${EMAIL}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(Country[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${COUNTRY}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(Sponsor[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${DESCRIPTION}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(DashboardUrl[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1http:\/\/${URL}:${PORT}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(IPv4Binding[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${IP}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(^Modules[[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${MODULES}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(DescriptionA[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${MODULEA}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/DescriptionD/DescriptionB/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(DescriptionB[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${MODULEB}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/DescriptionM/DescriptionC/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(DescriptionC[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${MODULEC}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/DescriptionS/DescriptionD/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(DescriptionD[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${MODULED}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "/\[Brandmeister\]/{n;s/\(Enable[[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${BRANDMEISTER}/;}" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "/\[USRP\]/{n;s/\(Enable[[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1${ALLSTAR}/;}" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(IPAddress[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${IP}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(RegistrationID[[:blank:]]*\=[[:blank:]]*\)[[:digit:]]*/\1${YSFID}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(RegistrationName[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${URFNUM}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(RegistrationDescription[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*/\1${DESCRIPTION}/g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(^FilePath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*dmrid.dat'\1${URFD_CONFIG_DIR}/dmrid.dat'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(^FilePath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*nxdn.dat'\1${URFD_CONFIG_DIR}/nxdn.dat'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(^FilePath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*ysfnode.dat'\1${URFD_CONFIG_DIR}/ysfnode.dat'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(XmlPath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*xlxd.xml'\1${URFD_CONFIG_DIR}/xlxd.xml'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s,\(Service\['XMLFile'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)',\1'${URFD_CONFIG_DIR}/xlxd.xml',g" ${URFD_DASH_CONFIG}
  sed -i "s'\(WhitelistPath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*urfd.whitelist'\1${URFD_CONFIG_DIR}/urfd.whitelist'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(BlacklistPath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*urfd.blacklist'\1${URFD_CONFIG_DIR}/urfd.blacklist'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(InterlinkPath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*urfd.interlink'\1${URFD_CONFIG_DIR}/urfd.interlink'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s'\(G3TerminalPath[[:blank:]]*\=[[:blank:]]*\)[[:print:]]*urfd.terminal'\1${URFD_CONFIG_DIR}/urfd.terminal'g" ${URFD_CONFIG_TMP_DIR}/urfd.ini
  sed -i "s/\(PageOptions\['IRCDDB'\]\['Show'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*/\1false/g" ${URFD_DASH_CONFIG}
  sed -i "s,\(CallingHome\['HashFile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\",\1\"${URFD_CONFIG_DIR}/callinghome.php\",g" ${URFD_DASH_CONFIG} # move callinghome file to /config
  sed -i "s,\(CallingHome\['LastCallHomefile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\",\1\"${URFD_CONFIG_DIR}\/lastcallhome.php\",g" ${URFD_DASH_CONFIG} # move lastcallhome file to /config
  sed -i "s,\(CallingHome\['InterlinkFile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\",\1\"${URFD_CONFIG_DIR}\/xlxd.interlink\",g" ${URFD_DASH_CONFIG} # move xlxd.interlink file to /config
  rm -f ${URFD_CONFIG_TMP_DIR}/urfd.service # get rid of systemd service
  rm -f ${URFD_CONFIG_TMP_DIR}/urfd.mk # remove pre-compile configuration file
  cp -vupn ${URFD_CONFIG_TMP_DIR}/* ${URFD_CONFIG_DIR}/ # don't overwrite config files if they exist
  rm -rf ${URFD_CONFIG_TMP_DIR}

fi

# set timezone
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

# generate virtual host
cat << EOF > /etc/apache2/sites-available/${URL}.conf
<VirtualHost *:${PORT}>
    ServerName ${URL}
    DocumentRoot ${URFD_WEB_DIR}
</VirtualHost>
EOF

# Configure default timezone in php
if [ ! -z ${TZ:-} ]; then
  echo "date.timezone = \""${TZ}"\"" >> /etc/php/*/apache2/php.ini

fi

# Configure httpd
echo "Listen ${PORT}" >/etc/apache2/ports.conf
echo "ServerName ${URL}" >> /etc/apache2/apache2.conf

# disable default site(s)
a2dissite *default >/dev/null 2>&1

# enable xlxd dashboard
a2ensite ${URL} >/dev/null 2>&1

touch /.firstRunComplete
echo "urfd first run setup complete"
