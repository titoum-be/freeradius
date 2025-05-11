export db_name=radius_db
export usr_name=radius
export usr_pwd=radpass

apt update
apt upgrade -y
cd /opt
mkdir radius_script
chmod 777 radius_script
cd radius_script

echo "/*
*
* PostgreSQL schema for $db_name
*
*/

/*
* Table structure for table 'radacct'
*
*/
CREATE TABLE IF NOT EXISTS radacct (
       RadAcctId               bigserial PRIMARY KEY,
       AcctSessionId           text NOT NULL,
       AcctUniqueId            text NOT NULL UNIQUE,
       UserName                text,
       Realm                   text,
       NASIPAddress            inet NOT NULL,
       NASPortId               text,
       NASPortType             text,
       AcctStartTime           timestamp with time zone,
       AcctUpdateTime          timestamp with time zone,
       AcctStopTime            timestamp with time zone,
       AcctInterval            bigint,
       AcctSessionTime         bigint,
       AcctAuthentic           text,
       ConnectInfo_start       text,
       ConnectInfo_stop        text,
       AcctInputOctets         bigint,
       AcctOutputOctets        bigint,
       CalledStationId         text,
       CallingStationId        text,
       AcctTerminateCause      text,
       ServiceType             text,
       FramedProtocol          text,
       FramedIPAddress         inet,
       FramedIPv6Address       inet,
       FramedIPv6Prefix        inet,
       FramedInterfaceId       text,
       DelegatedIPv6Prefix     inet,
       Class                   text
);

-- For use by update-, stop- and simul_* queries
CREATE INDEX radacct_active_session_idx ON radacct (AcctUniqueId) WHERE AcctStopTime IS NULL;

-- For use by on-off-
CREATE INDEX radacct_bulk_close ON radacct (NASIPAddress, AcctStartTime) WHERE AcctStopTime IS NULL;

-- and for common statistic queries:
CREATE INDEX radacct_start_user_idx ON radacct (AcctStartTime, UserName);

-- and for Class
CREATE INDEX radacct_calss_idx ON radacct (Class);

/*
* Table structure for table 'radcheck'
*/
CREATE TABLE IF NOT EXISTS radcheck (
       id                      serial PRIMARY KEY,
       UserName                text NOT NULL DEFAULT '',
       Attribute               text NOT NULL DEFAULT '',
       op                      VARCHAR(2) NOT NULL DEFAULT '==',
       Value                   text NOT NULL DEFAULT ''
);

create index radcheck_UserName on radcheck (UserName,Attribute);

/*
* Table structure for table 'radgroupcheck'
*/
CREATE TABLE IF NOT EXISTS radgroupcheck (
       id                      serial PRIMARY KEY,
       GroupName               text NOT NULL DEFAULT '',
       Attribute               text NOT NULL DEFAULT '',
       op                      VARCHAR(2) NOT NULL DEFAULT '==',
       Value                   text NOT NULL DEFAULT ''
);

create index radgroupcheck_GroupName on radgroupcheck (GroupName,Attribute);

/*
* Table structure for table 'radgroupreply'
*/
CREATE TABLE IF NOT EXISTS radgroupreply (
       id                      serial PRIMARY KEY,
       GroupName               text NOT NULL DEFAULT '',
       Attribute               text NOT NULL DEFAULT '',
       op                      VARCHAR(2) NOT NULL DEFAULT '=',
       Value                   text NOT NULL DEFAULT ''
);

create index radgroupreply_GroupName on radgroupreply (GroupName,Attribute);

/*
* Table structure for table 'radreply'
*/
CREATE TABLE IF NOT EXISTS radreply (
       id                      serial PRIMARY KEY,
       UserName                text NOT NULL DEFAULT '',
       Attribute               text NOT NULL DEFAULT '',
       op                      VARCHAR(2) NOT NULL DEFAULT '=',
       Value                   text NOT NULL DEFAULT ''
);

create index radreply_UserName on radreply (UserName,Attribute);

/*
* Table structure for table 'radusergroup'
*/
CREATE TABLE IF NOT EXISTS radusergroup (
       id                      serial PRIMARY KEY,
       UserName                text NOT NULL DEFAULT '',
       GroupName               text NOT NULL DEFAULT '',
       priority                integer NOT NULL DEFAULT 0
);

create index radusergroup_UserName on radusergroup (UserName);

--
-- Table structure for table 'radpostauth'
--

CREATE TABLE IF NOT EXISTS radpostauth (
       id                      bigserial PRIMARY KEY,
       username                text NOT NULL,
       pass                    text,
       reply                   text,
       CalledStationId         text,
       CallingStationId        text,
       authdate                timestamp with time zone NOT NULL default now(),
       Class                   text
);

CREATE INDEX radpostauth_username_idx ON radpostauth (username);
CREATE INDEX radpostauth_class_idx ON radpostauth (Class);

/*
* Table structure for table 'nas'
*/
CREATE TABLE IF NOT EXISTS nas (
       id                      serial PRIMARY KEY,
       nasname                 text NOT NULL,
       shortname               text NOT NULL,
       type                    text NOT NULL DEFAULT 'other',
       ports                   integer,
       secret                  text NOT NULL,
       server                  text,
       community               text,
       description             text
);

create index nas_nasname on nas (nasname);

/*
* Table structure for table 'nasreload'
*/
CREATE TABLE IF NOT EXISTS nasreload (
       NASIPAddress		inet PRIMARY KEY,
       ReloadTime		timestamp with time zone NOT NULL
);" > schema.sql

echo "
psql -c \"CREATE DATABASE $db_name\"
psql -c \"CREATE USER $usr_name WITH ENCRYPTED PASSWORD '$usr_pwd'\"
psql -c \"GRANT ALL PRIVILEGES ON DATABASE $db_name TO $usr_name\"
psql -c \"GRANT ALL PRIVILEGES ON SCHEMA public TO $usr_name\";
" > createUser.sh

echo "
psql postgresql://$usr_name:$usr_pwd@localhost:5433/$db_name -f /opt/radius_script/schema.sql
" > setupSchema.sh

chmod +x *.sh

#create cluster ver17
pg_createcluster 17 main

# start db
/etc/init.d/postgresql start

# std modification
su -c "sed -i '/^local/s/peer/scram-sha-256/' /etc/postgresql/17/main/pg_hba.conf" postgres
# fix issue https://dba.stackexchange.com/questions/83984/connect-to-postgresql-server-fatal-no-pg-hba-conf-entry-for-host 
su -c "echo 'host    all             all             0.0.0.0/0               scram-sha-256' >> /etc/postgresql/17/main/pg_hba.conf" postgres 

# Create user
su -c "sh /opt/radius_script/createUser.sh" postgres

# allow our user to create table in public
su -c "psql -d radius_db -c 'GRANT ALL PRIVILEGES ON SCHEMA public TO $usr_name'" postgres

# create radius schema
su -c "sh /opt/radius_script/setupSchema.sh" postgres

# restart db
/etc/init.d/postgresql restart
