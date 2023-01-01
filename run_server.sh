#!/bin/bash -ex
#echo "Hello, World" > index.html
#nohup busybox httpd -f -p 8080 &

  echo "*** Installing apache2"
  sudo apt-get update -y
  sudo apt-get install apache2 -y
  echo "*** Completed Installing apache2"