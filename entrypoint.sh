#!/bin/bash

set -xe

HOSTNAME=$FLY_APP_NAME.fly.dev

echo "Preparing to serve on https://${HOSTNAME}"

[ ! -f "client-1/cert.pem" ] && minica --domains client-1
[ ! -f "${HOSTNAME}/cert.pem" ] && minica --domains ${HOSTNAME}

rm /var/www/client.p12 || true
openssl pkcs12 -export -out /var/www/client.p12 -inkey client-1/key.pem -in client-1/cert.pem -certfile minica.pem -passout pass:password -legacy
chmod 666 /var/www/client.p12

if [ ! -f "certificates/${HOSTNAME}.crt" ]; then
  rm nginx.crt nginx.key || true
  ln -s ${HOSTNAME}/cert.pem nginx.crt
  ln -s ${HOSTNAME}/key.pem nginx.key
fi

sed s/HOST/${HOSTNAME}/g /etc/nginx/nginx.conf.tmpl > /etc/nginx/nginx.conf

nginx &

trap : INT

if [ ! -f "certificates/${HOSTNAME}.crt" ]; then
  # give DNS some time
  sleep 30

  until curl -s -f -o /dev/null "http://${HOSTNAME}"; do
    echo "waiting for deployment"
    sleep 5
  done

  lego --accept-tos --email ${EMAIL} --domains="${HOSTNAME}" --http.webroot "/var/www" --path "/work" --http run
else
  lego --accept-tos --email ${EMAIL} --domains="${HOSTNAME}" --http.webroot "/var/www" --path "/work" --http renew
fi

rm nginx.crt nginx.key || true
ln -s certificates/${HOSTNAME}.crt nginx.crt
ln -s certificates/${HOSTNAME}.key nginx.key
nginx -s reload

sleep infinity & wait
