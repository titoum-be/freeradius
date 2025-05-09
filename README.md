for postgre:

copy the folder at your prefered destination then type  docker compose up -d
once the container is created and started: docker  exec -it radius_postgresql /bin/bash
then issue following command:
* apt update
* apt install nano

nano install.sh (copy/past the content of the install.sh into it)
sh install.sh

congratulations! db is ready for radius :-)
