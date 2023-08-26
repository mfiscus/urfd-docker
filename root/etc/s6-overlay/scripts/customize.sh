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


# Function to edit urfd.ini values
# $1=Section
# $2=Property
# $3=Value
function __edit_value() {
    if [ ${#} -eq 3 ]; then
        local section=${1}
        local property=${2}
        local value=${3}

        sed -i "/^\[${section}\]/,/^\[/{s'\(^${property}[[:blank:]]*=[[:blank:]]*\)\([[:print:]]*\)'\1${value}'}" ${URFD_CONFIG_TMP_DIR}/urfd.ini

        return

    else
        exit 1

    fi

}


# Function to edit rename urfd.ini properties
# $1=Old property
# $2=New Property
function __edit_property() {
    if [ ${#} -eq 2 ]; then
        local old_property=${1}
        local new_property=${2}
        local file=${URFD_CONFIG_TMP_DIR}/urfd.ini

        sed -i "s/${old_property}/${new_property}/g" ${file}

        return

    else
        exit 1

    fi

}


# Function to comment out matched line
# $1=Section
# $2=Property
function __line_comment() {
    if [ ${#} -eq 2 ]; then
        local section=${1}
        local property=${2}
        local file=${URFD_CONFIG_TMP_DIR}/urfd.ini

        sed -i "/^\[${section}\]/,/^\[/{s'\(^${property}\)'#\ \1'}" ${file}

        return

    else
        exit 1

    fi

}


# Function to customize index.php
# $1=search
# $2=replace
function __edit_dashboard() {
    if [ ${#} -eq 2 ]; then
        local search=${1}
        local replace=${2}
        local file=${URFD_WEB_DIR}/index.php

        sed -i "s,${search},${replace},g" ${file}

        return

    else
        exit 1

    fi
    
}


# Function to edit values in config.inc.php
# $1=search
# $2=replace
function __edit_config() {
    if [ ${#} -eq 2 ]; then
        local search=${1}
        local replace=${2}
        local file=${URFD_WEB_DIR}/pgs/config.inc.php

        sed -i "s,${search},\1${replace},g" ${file}

        return

    else
        exit 1

    fi
    
}


# Function to delete matched line from files
# $1 = match for line to delete
# $2 = file
function __delete_line() {
    if [ ${#} -eq 2 ]; then
        local delete=${1}
        local file=${URFD_WEB_DIR}/${2}

        sed -i "/${delete}/d" ${file}

        return

    else
        exit 1

    fi

}


# Function to fix dates (convert to american)
# $1 = file
function __fix_date() {
    if [ ${#} -eq 1 ]; then
        local file=${URFD_WEB_DIR}/${1}

        sed -i "s/d\.m\.Y/m\.d\.Y/g" ${file}

        return

    else
        exit 1

    fi

}


# configure dashboard
if [ ! -z ${CALLSIGN:-} ]; then
  __edit_config "\(PageOptions\['MetaAuthor'\][[:blank:]]*\=[[:blank:]]*\)'\([[:alnum:]]*\)'" "'${CALLSIGN}'" # callsign

fi


if [ ! -z ${EMAIL:-} ]; then
  __edit_config "\(PageOptions\['ContactEmail'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'${EMAIL}'" # email address

fi


if [[ ${SSL:-} == "true" ]]; then
  __edit_dashboard "<?php echo \$Reflector->GetReflectorName(); ?> Multiprotocol Reflector" "<a href=\"https://${URL}/\"><img src=\"/img/logo.png\" alt=\"CHRC Logo\" width=\"50\" height=\"50\"></a>" # add custom logo
  __edit_config "\(CallingHome\['MyDashBoardURL'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'https:\/\/${URL}'" # URL

else
  __edit_dashboard "<?php echo \$Reflector->GetReflectorName(); ?> Multiprotocol Reflector" "<a href=\"http://${URL}:${PORT}/\"><img src=\"/img/logo.png\" alt=\"CHRC Logo\" width=\"50\" height=\"50\"></a>" # add custom logo
  __edit_config "\(CallingHome\['MyDashBoardURL'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'http:\/\/${URL}:${PORT}'" | grep "MyDashBoardURL" # URL

fi


__edit_config "\(CallingHome\['Country'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"" "\"$(echo ${COUNTRY} | awk '{gsub(/ /,"\\ ")}8')\"" # country
__edit_config "\(CallingHome\['Comment'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"" "\"$(echo ${DESCRIPTION} | awk '{gsub(/ /,"\\ ")}8')\"" # comment
__edit_config "\(CallingHome\['Active'\][[:blank:]]*\=[[:blank:]]*\)[[:alpha:]]*" "${CALLHOME}" # calling home toggle
__edit_config "\(Service\['XMLFile'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'${URFD_CONFIG_DIR}/xlxd.xml'" # path to xml file
__edit_config "\(CallingHome\['HashFile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"" "\"${URFD_CONFIG_DIR}/callinghome.php\"" # path to callinghome hash file
__edit_config "\(CallingHome\['LastCallHomefile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"" "\"${URFD_CONFIG_DIR}\/lastcallhome.php\"" # path to lastcallhome file
__edit_config "\(CallingHome\['InterlinkFile'\][[:blank:]]*\=[[:blank:]]*\)\"\([[:print:]]*\)\"" "\"${URFD_CONFIG_DIR}\/xlxd.interlink\"" # path to interlink file
__edit_config "\(PageOptions\['ModuleNames'\]\['A'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'${MODULEA}'" # name module A
__edit_config "\(PageOptions\['ModuleNames'\]\['B'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'${MODULEB}'" # name module B
__edit_config "\(PageOptions\['ModuleNames'\]\['C'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'${MODULEC}'" # name module C
__edit_config "\(PageOptions\['ModuleNames'\]\['D'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'${MODULED}'" # name module D
__edit_config "\(PageOptions\['RepeatersPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'HideIP'" # hide IP address on repeaters page
__edit_config "\(PageOptions\['PeerPage'\]\['IPModus'\][[:blank:]]*\=[[:blank:]]*\)'\([[:print:]]*\)'" "'HideIP'" # hide IP address on peers page
__delete_line "show=livequadnet" "index.php" # remove livequadnet
__delete_line "_GET\['show'\]\ ==\ \"livequadnet\"" "index.php" # remove livequadnet
__fix_date "pgs/users.php" # convert date format to US
__fix_date "pgs/peers.php" # convert date format to US
__fix_date "pgs/repeaters.php" # convert date format to US


# install configuration files
if [[ -e ${URFD_CONFIG_DIR:-} ]] && [[ -e ${URFD_CONFIG_TMP_DIR:-} ]]; then
  IP=$( hostname -I )
  
  if [[ ${SSL:-} == "true" ]]; then
    __edit_value "Names" "DashboardUrl" "https://${URL}"

  else
    __edit_value "Names" "DashboardUrl" "http://${URL}:${PORT}"
  
  fi


  __edit_value "Names" "Callsign" "${URFNUM}"
  __edit_value "Names" "SysopEmail" "${EMAIL}"
  __edit_value "Names" "Country" "${COUNTRY}"
  __edit_value "Names" "Sponsor" "${DESCRIPTION}"
  __edit_value "Modules" "Modules" "${MODULES}"
  __edit_value "Modules" "DescriptionA" "${MODULEA}"
  __edit_property "DescriptionD" "DescriptionB"
  __edit_value "Modules" "DescriptionB" "${MODULEB}"
  __edit_property "DescriptionM" "DescriptionC"
  __edit_value "Modules" "DescriptionC" "${MODULEC}"
  __edit_property "DescriptionS" "DescriptionD"
  __edit_value "Modules" "DescriptionD" "${MODULED}"
  __line_comment "Modules" "DescriptionZ"
  __edit_value "Brandmeister" "Enable" "${BRANDMEISTER}"
  __edit_value "NXDN" "ReflectorID" "${NXDNID}"
  __edit_value "P25" "ReflectorID" "${P25ID}"
  __edit_value "USRP" "Enable" "${ALLSTAR}"
  __edit_value "USRP" "Callsign" "${CALLSIGN}"
  __edit_value "USRP" "IPAddress" "${IP}"
  __edit_value "YSF" "RegistrationID" "${YSFID}"
  __edit_value "YSF" "RegistrationName" "${URFNUM}"
  __edit_value "YSF" "RegistrationDescription" "${DESCRIPTION}"
  __edit_value "DMR ID DB" "FilePath" "${URFD_CONFIG_DIR}/dmrid.dat"
  __edit_value "NXDN ID DB" "FilePath" "${URFD_CONFIG_DIR}/nxdn.dat"
  __edit_value "YSF TX\/RX DB" "FilePath" "${URFD_CONFIG_DIR}/ysfnode.dat"
  __edit_value "Files" "XmlPath" "${URFD_CONFIG_DIR}/xlxd.xml"
  __edit_value "Files" "WhitelistPath" "${URFD_CONFIG_DIR}/urfd.whitelist"
  __edit_value "Files" "BlacklistPath" "${URFD_CONFIG_DIR}/urfd.blacklist"
  __edit_value "Files" "InterlinkPath" "${URFD_CONFIG_DIR}/urfd.interlink"
  __edit_value "Files" "G3TerminalPath" "${URFD_CONFIG_DIR}/urfd.terminal"

  rm -f ${URFD_CONFIG_TMP_DIR}/*d.service # get rid of systemd service
  rm -f ${URFD_CONFIG_TMP_DIR}/*d.mk # remove pre-compile configuration file
  chown -R www-data:www-data ${URFD_CONFIG_DIR} # set ownership to www-data so callinghome.php and lastcallhome.php can be written
  cp -vupn ${URFD_CONFIG_TMP_DIR}/* ${URFD_CONFIG_DIR}/ # don't overwrite config files if they exist in case they have been manually edited
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
