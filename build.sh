sudo rm -fr build/
sudo meson build
cd build/
sudo ninja
sudo ninja install
cd ../
sudo service lightdm restart
