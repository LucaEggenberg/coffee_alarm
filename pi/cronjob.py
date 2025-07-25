import RPi.GPIO as GPIO
import time
from datetime import datetime, timedelta
import os
import logging
import json

log_path = '/coffee/cronJob.log'
config_path = '/coffee/config.json'
coffee_path = '/coffee/coffee.alarm'
espresso_path = '/coffee/espresso.alarm'
init_path = '/coffee/init'

gpio_pin = 17
coffee_duration_key = 'coffee_duration_seconds'
espresso_duration_key = 'espresso_duration_seconds'

logging.basicConfig(filename=log_path, encoding='utf-8', level=logging.DEBUG, format='%(asctime)s %(message)s')

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

def load_config():
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            return json.load(f)
    return {coffee_duration_key: 38, espresso_duration_key: 20}

def processFile(path: str, type_key: str):
    config = load_config()
    
    duration = config.get(type_key, 0)
    if duration == 0:
        logging.warning(f"duration for {type_key} does not exist, skipping")
        return

    if not os.path.exists(path):
        logging.info(f"file {path} does not exist, skipping")

    try:
        with open(path, 'r') as f:
            dateStr = f.read().strip('\n')
        dateobj = to_date(dateStr)

        if dateobj < datetime.now():
            logging.info(f'time for: {path.split("/")[-1]}')
            if get_last_init() + timedelta(minutes=5) < datetime.now():
                init_machine()
                time.sleep(35)
            make_coffee(duration)
            os.remove(path)
            logging.info("finished, enjoy :)")
    except Exception as e:
        logging.error(f"error processing {path}; Exception: {e}")

def make_coffee(duration: int):
    logging.info(f"making coffee...")
    GPIO.setup(gpio_pin, GPIO.OUT, initial=GPIO.HIGH)
    time.sleep(duration)
    GPIO.setup(gpio_pin, GPIO.OUT, initial=GPIO.LOW)

def init_machine():
    logging.info('initialising machine')
    with open(init_path, 'w') as f:
        f.write(to_date_string(datetime.now()))

    GPIO.setup(gpio_pin, GPIO.OUT, initial=GPIO.LOW)
    time.sleep(1)
    GPIO.setup(gpio_pin, GPIO.OUT, initial=GPIO.HIGH)
    time.sleep(0.5)
    GPIO.setup(gpio_pin, GPIO.OUT, initial=GPIO.LOW)

def get_last_init() -> datetime:
    if not os.path.exists(init_path):
        logging.warning(f"last initialization is not known, assuming none.")
        return to_date('1999-01-01 00:00:00')
    
    try:
        with open(init_path, 'r') as f:
            return to_date(f.read().strip('\n'))
    except ValueError as e:
        logging.error(f"error parsing time from {init_path}, assuming none.")
        return to_date('1999-01-01 00:00:00')
    except Exception as e:
        logging.error(f"an unexpected error occured reading last init time: {e}, assuming none")

def to_date(dateStr: str) -> datetime:
    return datetime.strptime(dateStr, '%Y-%m-%d %H:%M:%S')

def to_date_string(dateObj: datetime) -> str:
    return datetime.strftime(dateObj, '%Y-%m-%d %H:%M:%S')

if os.path.exists(coffee_path):
    processFile(coffee_path, coffee_duration_key)

if os.path.exists(espresso_path):
    processFile(espresso_path, espresso_duration_key)
    