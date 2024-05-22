# Lamp_install
A script to install the LAMP stach (without linux ,assuming that this is ran on linux)
LAMP (linux, apache, mariadb, php) stack downloading, building, installing, configuring script.

# Usage:

**chmod +x lamp_install.sh**

**./lamp_install.sh**

* Default installation dir is /opt

* If need be you can configure the script internally to change the versions of the programs or the installation dir.

# Info:

* The script sets up so that apache and mariadb run on boot.
* To check use sudo systemctl status/start/restart/stop apache/mariadb


# Challenges:
    * Getting a hold of of all the dependencies. (fixed)
    * Encountered major trouble (I think it works now?) to figure out how to set up mariaDB server and how to test it. (weird test in place)
    * Having major downtime while waiting for everything to build just to find that it doesn't work properly and that I missed something.
    * Figuring out how to start apache on boot (fixed)
    * Now it's a challenge figuring out why php doesn't work on apache (fixed)

# QOL changes that I think would be nice:
    * Custom installation paths as arguments or prompts
    * Choice between versions of the software
