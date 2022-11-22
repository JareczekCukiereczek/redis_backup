#!/bin/bash
APP_DIR=/root/DEVOPS/01_BASH/Python_app
LOG_FILE=./install.log

function log_and_print() {
    echo "`date "+%Y.%m.%d %X"` $1"
    echo "`date "+%Y.%m.%d %X"` $1" >> $LOG_FILE
}


function install() {
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
    WorkingDirectory=$APP_DIR
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

function backup() {
    log_and_print "Rozpoczynam backup redisa"
    redis-cli save > /dev/null
    if [ $? != 0 ]; then
        log_and_print "Backup redisa zakończony błędem"
        exit 2
    fi
    mkdir -p /backup
    log_and_print "Przenosze backup do katalogu /backup"
    mv /var/lib/redis/dump.rdb /backup/`date "+%Y_%m_%d"`_redis.backup
    log_and_print "Backup zakończony"
}
function rollback() {
    if [ -a $1 ]; then
        log_and_print "Zmienna po rollback przekzujaca nazwe pliku do przywrocenia jest pusta!!"
        exit 2
    fi
    if [ ! -e /backup/$1 ]; then
        log_and_print "Plik /backup/$1 nie istnieje!!"
        exit 2
    fi
    log_and_print "Rozpoczynam rollback redisa"
    log_and_print "Zeruje counter"
    redis-cli DEL counter > /dev/null
    if [ $? != 0 ]; then
        log_and_print "Zerowanie countera zakończone błędem"
        exit 2
    fi
    log_and_print "Zatrzymuje redisa"
    service redis-server stop
    if [ $? != 0 ]; then
        log_and_print "Zatrzymywanie redisa zakończone błędem"
        exit 2
    fi

    cp /backup/$1 /var/lib/redis/dump.rdb
    log_and_print "Startujemy redisa"
    service redis-server start
    if [ $? != 0 ]; then
        log_and_print "Startowanie redisa zakończone błędem"
        exit 2
    fi
    rm /var/lib/redis/dump.rdb
    log_and_print "Rollback zakończony sukcesem"
}


case "$1" in
    "backup") backup;;
    "rollback") rollback $2;;
    *) echo "skrypt przyjmuje parametry rollback lub backup";;
esac 
