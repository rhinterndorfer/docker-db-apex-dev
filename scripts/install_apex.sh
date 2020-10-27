#!/bin/bash

disable_http(){
    echo "Turning off DBMS_XDB HTTP port"
    echo "EXEC DBMS_XDB.SETHTTPPORT(0);" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA
}


apex_create_tablespace(){
    cd ${ORACLE_HOME}/apex
    echo "Creating APEX tablespace."

    ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA <<EOF
		CREATE TABLESPACE apex DATAFILE '${ORACLE_BASE}/oradata/XE/apex01.dbf' SIZE 256M AUTOEXTEND ON NEXT 64M;
EOF
}

apex_install(){
    cd $ORACLE_HOME/apex
    echo "Installing APEX."
    echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA @apexins APEX APEX TEMP /i/
}

apex_change_admin_pwd(){
    cd $ORACLE_HOME/apex
    echo "Changing APEX Admin Password"

    APEX_SCHEMA=`sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT ao.owner FROM all_objects ao WHERE ao.object_name = 'WWV_FLOW' AND ao.object_type = 'PACKAGE' AND ao.owner LIKE 'APEX_%';
EXIT;
EOF`

    echo "begin" > apxchpwd_custom.sql
    echo "    wwv_flow_security.g_security_group_id := 10;" >> apxchpwd_custom.sql
    echo "    wwv_flow_security.g_user              := 'admin';" >> apxchpwd_custom.sql
    echo "    wwv_flow_fnd_user_int.create_or_update_user( p_user_id  => NULL," >> apxchpwd_custom.sql
    echo "                                                 p_username => 'admin'," >> apxchpwd_custom.sql
    echo "                                                 p_email    => 'admin'," >> apxchpwd_custom.sql
    echo "                                                 p_password => '${APEX_PASS}' );" >> apxchpwd_custom.sql
    echo "    commit;" >> apxchpwd_custom.sql
    echo "end;" >> apxchpwd_custom.sql
    echo "/" >> apxchpwd_custom.sql

    ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA <<EOF
ALTER SESSION SET CURRENT_SCHEMA=${APEX_SCHEMA};
@apxchpwd_custom.sql
EXIT;
EOF
}

apex_install_lang(){
    cd $ORACLE_HOME/apex/builder/${APEX_ADDITIONAL_LANG}
    echo "Installing APEX Language Pack ${APEX_ADDITIONAL_LANG}"
    export NLS_LANG=AMERICAN_AMERICA.AL32UTF8;

    APEX_SCHEMA=`sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA <<EOF
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF
SELECT ao.owner FROM all_objects ao WHERE ao.object_name = 'WWV_FLOW' AND ao.object_type = 'PACKAGE' AND ao.owner LIKE 'APEX_%';
EXIT;
EOF`

    ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA <<EOF
ALTER SESSION SET CURRENT_SCHEMA=${APEX_SCHEMA};
@load_${APEX_ADDITIONAL_LANG}.sql
EXIT;
EOF

    unset NLS_LANG
}

apex_load_images() {
    echo "Load APEX images."
    # do not load images from path containing soft links to avoid "ORA-22288: file or LOB operation FILEOPEN failed"
    echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA @apxldimg.sql `readlink -f ${ORACLE_HOME}`
}

apex_rest_config() {
    echo "Getting ready for ORDS. Creating user APEX_LISTENER and APEX_REST_PUBLIC_USER."
    echo -e "${PASS}\n${PASS}" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS sysdba @apex_rest_config.sql
    echo "ALTER USER APEX_PUBLIC_USER ACCOUNT UNLOCK;" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA
    echo "ALTER USER APEX_PUBLIC_USER IDENTIFIED BY ${PASS};" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA
}

apex_allow_all_acl() {
    echo "BEGIN" > create_allow_all_acl.sql
    echo "  BEGIN" >> create_allow_all_acl.sql
    echo "    dbms_network_acl_admin.drop_acl(acl => 'all-network-PUBLIC.xml');" >> create_allow_all_acl.sql
    echo "  EXCEPTION" >> create_allow_all_acl.sql
    echo "    WHEN OTHERS THEN" >> create_allow_all_acl.sql
    echo "      NULL;" >> create_allow_all_acl.sql
    echo "  END;" >> create_allow_all_acl.sql
    echo "  dbms_network_acl_admin.create_acl(acl         => 'all-network-PUBLIC.xml'," >> create_allow_all_acl.sql
    echo "                                    description => 'Allow all network traffic'," >> create_allow_all_acl.sql
    echo "                                    principal   => 'PUBLIC'," >> create_allow_all_acl.sql
    echo "                                    is_grant    => TRUE," >> create_allow_all_acl.sql
    echo "                                    privilege   => 'connect');" >> create_allow_all_acl.sql
    echo "  dbms_network_acl_admin.add_privilege(acl       => 'all-network-PUBLIC.xml'," >> create_allow_all_acl.sql
    echo "                                       principal => 'PUBLIC'," >> create_allow_all_acl.sql
    echo "                                       is_grant  => TRUE," >> create_allow_all_acl.sql
    echo "                                       privilege => 'resolve');" >> create_allow_all_acl.sql
    echo "  dbms_network_acl_admin.assign_acl(acl  => 'all-network-PUBLIC.xml'," >> create_allow_all_acl.sql
    echo "                                    host => '*');" >> create_allow_all_acl.sql
    echo "END;" >> create_allow_all_acl.sql
    echo "/" >> create_allow_all_acl.sql
    echo "sho err" >> create_allow_all_acl.sql
    echo "COMMIT;" >> create_allow_all_acl.sql
    echo "/" >> create_allow_all_acl.sql

    echo "EXIT" | ${ORACLE_HOME}/bin/sqlplus -s -l sys/${PASS}@127.0.0.1/XEPDB1 AS SYSDBA @create_allow_all_acl.sql
}

unzip_apex(){
    echo "Extracting APEX"
    rm -rf ${ORACLE_HOME}/apex
    unzip /files/apex*.zip -d ${ORACLE_HOME}/ > /dev/null
}

echo "Installing APEX in DB: ${ORACLE_SID}"
. /home/oracle/.bash_profile
unzip_apex
disable_http
apex_create_tablespace
apex_install
apex_change_admin_pwd
apex_rest_config
apex_allow_all_acl
if [ ! -z "${APEX_ADDITIONAL_LANG}" ]; then
    apex_install_lang
fi
cd /
