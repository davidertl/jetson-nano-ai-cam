#!/bin/bash

~/skip_sudo.sh
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y v4l-utils
sudo apt-get install -y gawk curl

sudo apt-get install -y python3-pip libhdf5-serial-dev hdf5-tools


##for deepstreem 4
sudo apt install \
   libssl1.0.0 \
   libgstreamer1.0-0 \
   gstreamer1.0-tools \
   gstreamer1.0-plugins-good \
   gstreamer1.0-plugins-bad \
   gstreamer1.0-plugins-ugly \
   gstreamer1.0-libav \
   libgstrtspserver-1.0-0 \
   libjansson4=2.11-1



##for opencv 4
dependencies=(build-essential cmake pkg-config libavcodec-dev libavformat-dev libswscale-dev libv4l-dev libxvidcore-dev libavresample-dev python3-dev libtbb2 libtbb-dev libtiff-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev libgtk-3-dev libcanberra-gtk3-module libatlas-base-dev gfortran wget unzip)

sudo apt install -y ${dependencies[@]}

##for deepstream
sudo apt-get update
sudo apt-get install v4l-utils
sudo apt-get install gawk
sudo apt-get install curl

sudo snap install modem-manager
sudo snap install network-manager


##for tensorflow

#sudo systemctl set-default multi-user.target

sudo apt-get install -y build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get install -y python3.6-dev python-dev python-numpy python3-numpy
sudo apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libjasper-dev libdc1394-22-dev
sudo apt-get install -y libv4l-dev v4l-utils qv4l2 v4l2ucp
sudo apt-get install -y curl


sudo apt-get install -y libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev liblapack-dev libblas-dev gfortran

sudo apt-get install -y build-essential libatlas-base-dev
sudo apt-get install -y python3-scipy
sudo apt-get install -y python-numpy python-scipy python-matplotlib ipython ipython-notebook python-pandas python-sympy python-nose


sudo apt-get install -y python3-pip

#sudo pip3 install --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v42 tensorflow-gpu

##https://developer.nvidia.com/embedded/downloads#?search=tensorflow
sudo -H pip3 install --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v43 tensorflow==1.15.2+nv20.2

sudo -H pip3 install -U pip testresources setuptools

#sudo pip3 install -U numpy==1.16.1 future==0.17.1 mock==3.0.5 h5py==2.9.0 keras_preprocessing==1.0.5 keras_applications==1.0.8 gast==0.2.2 futures protobuf pybind11

sudo -H pip3 install -U numpy future mock h5py keras_preprocessing keras_application gast futures protobuf pybind11 grpcio absl-py py-cpuinfo psutil portpicker six mock requests gast h5py astor termcolor protobuf keras-applications keras-preprocessing wrapt google-pasta



#sudo dpkg -i OpenCV-4.1.1-dirty-aarch64-*.deb

sudo apt-get --with-new-pkgs upgrade
sudo apt autoremove
apt-get dist-upgrade