# makefile for coffee_alarm serverside files
.PHONY: all install setup_directories install_system_deps install_python_deps setup_services run clean

PROJECT_DIR := /home/pi/coffee_alarm
API_FILE := api.py
CRONJOB_FILE := cronjob.py

CONFIG_FILE := config.json
WOKRING_DIR := /coffee
API_SERVICE_NAME := coffee_alarm.api.service

SYSTEM_DEPS := hostapd dnsmasq
PYTHON_DEPS := fastapi uvicorn python-multipart RPi.GPIO pydantic

all: install

install: setup_directories install_system_deps install_python_deps setup_services
	@echo ""
	@echo "******************************************************************"
	@echo "* installation complete											*"
	@echo "* please reboot for changes to take effect						*"
	@echo "******************************************************************"
	@echo ""

setup_directories:
	@echo "setting directories and permissions..."
	sudo mkdir -p $(PROJECT_DIR)
	sudo mkdir -p $(WOKRING_DIR)
	sudo chmod 777 $(WOKRING_DIR)

install_system_deps:
	@echo "installing system dependencies..."
	sudo apt update
	sudo apt install -y python3 python3-pip $(SYSTEM_DEPS)

install_python_deps:
	@echo "installing pip dependencies..."
	pip install --upgrade pip
	pip install $(PYTHON_DEPS)

setup_services:
	@echo "setting up systemd services and cronjobs..."

	sudo cp $(API_FILE) $(PROJECT_DIR)/$(API_FILE)
	sudo cp $(CRONJOB_FILE) $(PROJECT_DIR)/$(CRONJOB_FILE)
	sudo cp $(CONFIG_FILE) $(PROJECT_DIR)/$(CONFIG_FILE)

	# create systemd service for api
	echo "[Unit]" | sudo tee /etc/systemd/system/$(API_SERVICE_NAME)
	echo "Description=coffee_alarm webapi" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "After=multi-user.target" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "[Service]" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "Type=simple" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "ExecStart=/usr/local/bin/uvicorn --app-dir $(PROJECT_DIR) api:app --reload --host 0.0.0.0 --port 8000" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "Restart=on-failure" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "RestartSec=5" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "[Install]" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)
	echo "WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/$(API_SERVICE_NAME)

	# set permissions & enable
	sudo chmod 644 /etc/systemd/system/$(API_SERVICE_NAME)
	sudo systemctl daemon-reload
	sudo systemctl enable $(API_SERVICE_NAME)
	sudo systemctl start $(API_SERVICE_NAME)
	@echo "api service enabled and started"
	
	(sudo crontab -l 2>/dev/null; echo "* * * * * /usr/bin/python3 $(PROJECT_DIR)/$(CRONJOB_FILE) | sudo tee -a  $(WOKRING_DIR)/cron.log 2>&1") | sudo crontab -
	@echo "cronjob created"