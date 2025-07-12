from pydantic import BaseModel
from datetime import datetime
import RPi.GPIO as GPIO
import os
import json
from fastapi import FastAPI

GPIO.setmode(GPIO.BCM)
GPIO.setwarnings(False)

app = FastAPI()

class SetGPIO(BaseModel):
    on: bool

class SetConfig(BaseModel):
    coffee_duration_seconds: int
    espresso_duration_seconds: int

coffee_path = '/coffee/coffee.alarm'
espresso_path = '/coffee/espresso.alarm'
config_path = '/coffee/config.json'

def initialize_config():
    if not os.path.exists(config_path):
        default_config = {
            "coffee_duration_seconds": 38,
            "espresso_duration_seconds": 20
        }
        os.makedirs(os.path.dirname(config_path), exist_ok=True)
        with open(config_path, 'w') as f:
            json.dump(default_config, f, indent=4)

def delete_files():
    if os.path.exists(coffee_path):
        os.remove(coffee_path)
    if os.path.exists(espresso_path):
        os.remove(espresso_path)

def make_file(path: str, time: datetime):
    deleteFiles()
    f = open(path, 'x')
    f.write(time.strftime('%Y-%m-%d %H:%M:%S'))
    f.close()

def get_time(path: str) -> datetime:
    return datetime.strptime(open(path, 'r').read(), '%Y-%m-%d %H:%M:%S')

initialize_config()

@app.get("/read/{gpio}")
def read_root(gpio: int):
    GPIO.setup(gpio, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)
    return {"gpio": gpio, "on": GPIO.input(gpio)}

@app.patch("/set/{gpio}")
def read_item(gpio: int, value: SetGPIO):
    if value.on:
        GPIO.setup(gpio, GPIO.OUT, initial=GPIO.HIGH)
    else:
        GPIO.setup(gpio, GPIO.OUT, initial=GPIO.LOW)
    return {"gpio": gpio, "on": value.on}

@app.put("/timer/coffee")
def set_coffee_timer(time: datetime):
    make_file(coffee_path, time)
    return {"message": "coffee timer set"}

@app.put("/timer/espresso")
def set_espresso_timer(time: datetime):
    make_file(espresso_path, time)
    return {"message": "espresso timer set"}

@app.delete("/timer")
def delete_timers():
    delete_files()
    return {"message": "timers deleted"}

@app.get("/timer")
def get_active_timer():
    if os.path.exists(coffee_path):
        return {"coffee": "coffee", "time": get_time(coffee_path)}
    if os.path.exists(espresso_path):
        return {"coffee": "espresso", "time": get_time(espresso_path)}
    return {"coffee": None, "time": None}

@app.get("/config")
def get_config():
    with open(config_path, 'r') as f:
        config_data = json.load(f)
    return config_data

@app.put("/config")
def set_config():
    with open(config_path, 'w') as f:
        json.dump(config.dict(), f, indent=4)
    return {"message": "configuration updated", "config": config.dict()}
