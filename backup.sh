#!/bin/bash

APP_DIR=/root/DEVOPS/01_BASH/Python_app
LOG_FILE=./install.log

function log_and_print(){
    echo "date '+%Y_%m_%d_%h_%m' $1"
}

function install(){
    #!/bin/bash
apt-get update
apt-get install --no-install-recommends -y python3 redis python3-pip uvicorn
cd $APP_DIR
if [ $? != 0 ]; then
    echo "Instalation failed"
    exit 2
fi

pip3 install --no-cache-dir -r requirements.txt

echo "[Unit]
Description=Python API
After=network.target

[Service]
WorkingDirectory=/root/DEVOPS/01_BASH/Python_app
Type=simple
Environment=REDIS_HOST=127.0.0.1
ExecStart=/usr/bin/uvicorn main:app --host 0.0.0.0 --port 5002
StandardInput=tty-force

[Install]
WantedBy=multi-user.target" > /lib/systemd/system/python-api.service

systemctl daemon-reload
systemctl enable python-api.service
systemctl start python-api.service
}
redis-cli save
mkdir -p /backup


log_and_print "Przenosze backup do katalogu /backup"
mv /var/lib/redis/dump.rdb /backup/`date "+%Y_%m_%d"`_redis.backup
log_and_print "Backup zakonczony"
