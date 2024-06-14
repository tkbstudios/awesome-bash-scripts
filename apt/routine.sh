#!/bin/bash

echo "Updating package list..."
sudo apt-get update

echo "Upgrading installed packages..."
sudo apt-get upgrade -y

echo "Removing unnecessary packages..."
sudo apt-get autoremove -y

echo "Cleaning up..."
sudo apt-get clean

echo "System update completed!"
