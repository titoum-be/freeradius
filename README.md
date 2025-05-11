for postgre:

copy the folder at your prefered destination then type  docker compose up -d
once the container is created and started: docker  exec -it radius_postgresql /bin/bash
then issue following command:
* apt update
* apt install nano

nano install.sh (copy/past the content of the install.sh into it)
you can edit your preferences:
  * export db_name=radius_db --> db name of your install
  * export usr_name=radius --> user name to be used (not postgres for security reason)
  * export usr_pwd=radpass --> user password

sh install.sh

congratulations! db is ready for radius :-)

For Radius:

copy the folder at your prefered place.
run: docker build -t freeradius_3.2.8 -f Dockerfile .
then if all is fine.
run: docker run  --rm --name radius_server -t -p 1812-1813:1812-1813/udp freeradius_3.2.8 -X

hint: 
 Dont forget to populate your db before starting as it wont take new entries once started.
 you can easily edit your db entries through the adminer: http://[radius-db]:5050/
