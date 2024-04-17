#Install Dependencies
sudo apt install cmake ninja-build golang

#Build BoringSSL
cmake -GNinja -B build
ninja -C build
