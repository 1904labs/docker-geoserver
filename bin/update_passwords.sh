#!/bin/bash 
# Credits https://github.com/geosolutions-it/docker-geoserver for this script that allows a user to pass a password
# or username on runtime.

if [ ${DEBUG} ]; then
    set -ex
fi;

GEOSERVER_DIR="${GEOSERVER_DIR:-${CATALINA_HOME}/webapps/geoserver}"
GEOSERVER_DATA_DIR="${GEOSERVER_DATA_DIR:-${GEOSERVER_DIR}/data}"
GEOSERVER_ADMIN_USER=${GEOSERVER_ADMIN_USER:-admin}
GEOSERVER_ADMIN_PASSWORD=${GEOSERVER_ADMIN_PASSWORD:-geoserver}
USERS_XML=${USERS_XML:-${GEOSERVER_DATA_DIR}/security/usergroup/default/users.xml}
ROLES_XML=${ROLES_XML:-${GEOSERVER_DATA_DIR}/security/role/default/roles.xml}
CLASSPATH=${CLASSPATH:-${GEOSERVER_DIR}/WEB-INF/lib/}
SETUP_LOCKFILE="${GEOSERVER_DATA_DIR}/.updatepassword.lock"

set_username(){
  # roles.xml setup
  # <userRoles username="admin">
  sed -e "s/ username=\".*\"/ username=\"${GEOSERVER_ADMIN_USER}\"/" -i ${ROLES_XML}

}

set_password(){
  PWD_HASH=$(java \
    -classpath $(find $CLASSPATH -regex ".*jasypt-[0-9]\.[0-9]\.[0-9].*jar") \
    org.jasypt.intf.cli.JasyptStringDigestCLI digest.sh algorithm=SHA-256 \
    saltSizeBytes=16 iterations=100000 input="${GEOSERVER_ADMIN_PASSWORD}" \
    verbose=0 | tr -d '\n'
    )

  # users.xml setup
  # <user enabled="true" name="admin" password="digest1:7/qC5lIvXIcOKcoQcCyQmPK8NCpsvbj6PcS/r3S7zqDEsIuBe731ZwpTtcSe9IiK"/>
  sed \
    -e "s/ name=\".*\" / name=\"${GEOSERVER_ADMIN_USER}\" /" \
    -e "s/ password=\".*\"/ password=\"digest1:${PWD_HASH//\//\\/}\"/" \
    -i $USERS_XML
}

if [ ! -f "${SETUP_LOCKFILE}" ]; then
  set_username
  set_password
  # Put lock file to make sure password is not reinitialized on restart
  touch ${SETUP_LOCKFILE}
fi