# Install DK Manager

## Create working directory
```
sudo mkdir /usr/bin/dreamkit
sudo chown dev /usr/bin/dreamkit
sudo chgrp dev /usr/bin/dreamkit
cd /usr/bin/dreamkit
```

## Build Install socket.io cpp lib

Build With CMake
```
mkdir ~/dream && cd ~/dream
sudo apt update
sudo apt install build-essential
sudo apt  install -y cmake
sudo apt-get install -y libssl-dev
git clone --recurse-submodules https://github.com/socketio/socket.io-client-cpp.git
cd socket.io-client-cpp
cmake  ./
sudo make install
```

Build and install result
```
[100%] Built target sio_test
Install the project...
-- Install configuration: "Release"
-- Up-to-date: /usr/local/include/sio_client.h
-- Up-to-date: /usr/local/include/sio_message.h
-- Up-to-date: /usr/local/include/sio_socket.h
-- Installing: /usr/local/lib/libsioclient.a
-- Installing: /usr/local/lib/libsioclient_tls.a
-- Old export file "/usr/local/lib/cmake/sioclient/sioclientTargets.cmake" will be replaced.  Removing files [/usr/local/lib/cmake/sioclient/sioclientTargets-release.cmake].
-- Installing: /usr/local/lib/cmake/sioclient/sioclientTargets.cmake
-- Installing: /usr/local/lib/cmake/sioclient/sioclientTargets-release.cmake
-- Up-to-date: /usr/local/lib/cmake/sioclient/sioclientConfig.cmake
-- Up-to-date: /usr/local/lib/cmake/sioclient/sioclientConfigVersion.cmake
-- Up-to-date: /usr/local/lib/cmake/sioclient/sioclientTargets.cmake
```

## Build and install dk-manager

```
cd ~/dream
sudo apt update
sudo apt install qt6-base-dev

git clone --recurse-submodules https://github.com/ppa2hc/dk-manager.git
cd dk-manager
mkdir build
cd build
qmake6 ../dk-manager.pro
make
cp ./dk-manager /usr/bin/dk-manager
```
