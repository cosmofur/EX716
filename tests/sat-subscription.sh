#!/bin/sh

###############################################################################
# Optimized and updated sat-subscription.sh
###############################################################################

# Defaults
OSVERSION=$(cat /etc/redhat-release)
OSRELEASE=$(cat /etc/redhat-release | grep -oP "[0-9]+" | head -1)
KATELLOURL=pub/katello-ca-consumer-latest.noarch.rpm
ACTIVATEKEY="RedHat-7-Dev"
ACTIVATEKEY="noset"
FORCEURL="none"
UsePort=443

USEENV=none
if [ -z "$1" ]; then
    echo "Usage $i [-2] [-d][-p] [-b BaseURL]"
    exit
fi

SECRUN=false
NEWOPTS=""
USEROLDSSL=false

while getopts "dpu2fhb:" FLAG; do
    case $FLAG in
        d)
            # Dev
            USEENV="Dev"
            ACTIVATEKEY="-Dev"
            NEWOPTS="$NEWOPTS -d"
            ;;
        u)
            # UAT
            USEENV="UAT"
            ACTIVATEKEY="-UAT"
            NEWOPTS="$NEWOPTS -u"
            ;;
        p)
            # Prod
            USEENV="Prod"
            ACTIVATEKEY="-Prod"
            NEWOPTS="$NEWOPTS -p"
            ;;
        b)
            # Force a given base url.
            FORCEURL="$OPTARG"
            NEWOPTS="$NEWOPTS -b $OPTARG"
            ;;
        f)
            # Fix UUID info
            cat > /etc/rhsm/facts/uuid.facts << EOF
{"dmi.system.uuid": "`uuidgen`"}

EOF
            exit 0
            ;;
        2)
            SECRUN=true
            ;;
        s)
            USEOLDSSL=true
            NEWOPTS="$NEWOPTS -s"
            ;;
        h)
            echo "Usage: "
            echo "-d Development Servers"
            echo "-u UAT Servers"
            echo "-p Production Servers"
            echo "-b URL forces use of given base URL"
            echo "-2 Run without checking for updated sat-subscription.sh script"
            echo "-s Use normal 443 SSL rather that default 8443 SSL for PCI zones"
            exit
            ;;
        *)
            echo "Invalid option"
            exit
            ;;
    esac
done

URLLIST=(
    https://capsule-corp-prod.wawa.com
    https://capsule-pci-prod.wawa.com
    https://capsule-aws-1.wawa.com
    https://capsule-tierpoint-non-pci.wawa.com
    https://capsule-tierpoint-pci.wawa.com
)

#######
# If the user passed a 'BestHost' we'll trust he knows what he's doing.
if [ "$FORCEURL" -ne "none" ]; then
    BESTHOST="$FORCEURL"
else
    #######
    # If there is already a /tmp/yum-server file then try to use that.
    if [ -e /tmp/yum-server ]; then
        CheckHost=$((cat /tmp/yum-server))
        if curl -k -s --connect-timeout 3 -I $CheckHost 2>&1 > /dev/null ; then
            BESTHOST="$CheckHost"
        else
            # /tmp/yum-server seems wrong. Save it for later debugging if needed
            mv /tmp/yum-server /tmp/yum-server.`date`
            BESTHOST="none"
        fi
    fi
fi
######
# If BESTHOST is still none, then try to find what it should be

if [ "$BESTHOST" -eq "none" ]; then
    for testurl in ${URLLIST[@]}
    do
        echo -n "."
        # Default is to use 8443, but some FW rules require 443, use -s for thoses.
        if [ $USEOLDSSL == "false" ]; then
            testport=$(echo "$testurl:8443")
            UsePort=8443
        else
            testport=$(echo "$testurl:443")
            UsePort=443
        fi
        echo -n " $testport is being tested."
        if curl -k -s --connect-timeout 3 -I $testport  2>&1 > /dev/null ; then
            BESTHOST="$(echo $testport)"
        fi
        echo ""
    done
fi
echo BESTHOST = $BESTHOST
if [ "$BESTHOST" -eq "none" ]; then
    echo "No valid host found. Capsule networks unreachable."
    exit -1
fi
BESTNAME="$( echo $testport | sed 's?https://??')"
echo $BESTHOST > /tmp/yum-server
KATELLOURL="https://$BESTHOST/$KATELLOURL"
#
# If SECRUN is false, check server if there is an upgrad to sat-subscription.sh
if [ $SECRUN == "false" ]; then
    echo "Refreshing $0 from /pub/ on $BESTHOST"
    echo $BESTHOST > /tmp/satellite.host
    mv /root/sat-subscription.sh /root/sat-subscription.sh.o
    wget -O /root/sat-subscription.sh https://$BESTHOST/pub/sat-subscription.sh
    bash /root/sat-subscription.sh -2 -b "$BESTHOST" $NEWOPTS
    exit
fi
#
#
# We need OS Info Now.
# 
ID the OS info.
if [[ $OSVERSION == *Enterprise* ]]; then
    OS="RedHat"
    SUBMANAGER="el${OSRELEASE}_sub_manager_repo"
    ACTIVATEKEY="${OS}-${OSRELEASE}-${USEENV}"
elif [[ $OSVERSION == *AlmaLinux* ]]; then
    OS="AlmaLinux"
    SUBMANAGER="el${OSRELEASE}_sub_manager_repo"
    ACTIVATEKEY="${OS}-${OSRELEASE}-${USEENV}"
elif [[ $OSVERSION == *release* ]]; then
    OS="CentOS"
    SUBMANAGER="el${OSRELEASE}_sub_manager_repo"
    ACTIVATEKEY="${OS}-${OSRELEASE}-${USEENV}"
fi

##############################################
# Begin on-boarding the system to satellite  #
##############################################

sudo subscription-manager config --rhsm.manage_repos=0
sudo subscription-manager config --server.hostname=$BASENAME --server.port="$UsePort"

yum clean all
echo BaseURL is $BASEURL
echo ActivateKey is $ACTIVATEKEY
echo SUBMANAGER is $SUBMANAGER
# Create new uuid for template
cat > /etc/rhsm/facts/uuid.facts << EOF
{"dmi.system.uuid": "`uuidgen`"}
EOF

###############################################
# Install Katello, make sure subscription-manager is upto date, then remove it again.

sudo curl --connect-timeout 5 -k -o katello-ca-consumer-latest.noarch.rpm  $BASEURL
sudo yum -y install subscription-manager
# There is high chance that all calls to yum and subscription manager will ignorm the repos=0
# So reset it again
sudo subscription-manager config --rhsm.manage_repos=0
#
sudo subscription-manager config --rhsm.auto_enable_yum_plugins=0
sudo subscription-manager remove --all
sudo subscription-manager clean
sudo subscription-manager config --rhsm.manage_repos=0
#
# Katello had it chance to 'fix' subscription-manager, get rid of it.
sudo yum -y remove katello-ca-consumer-capsule* katello-agent* *gofer* *qpid* *proton*
sudo yum -y localinstall katello-ca-consumer-latest.noarch.rpm
#
# Now comes the 'real' subscription manager command, echo it first so we can see what
# was generated for ActivateKey
echo sudo subscription-manager register --org="WAWA" --activationkey="$ACTIVATEKEY" --force
sudo subscription-manager register --org="WAWA" --activationkey="$ACTIVATEKEY" --force

# Now that we 'should' have a working repo, test it by installing the updated foreman
sudo yum clean all
sudo yum repolist
sudo yum -y install katello-host-tools* --nogpgcheck
#sudo rm -rf /etc/yum.repos.d/$SUBMANAGER.repo

# Add foreman-proxy user for remote execution

USER=foreman-proxy
FILE1=/home/foreman-proxy/.ssh/authorized_keys
FILE2=/etc/sudoers.d/foreman-proxy
FILE3=/home/foreman-proxy/.ssh

#######################################################
# Check if satellite user exist on the client machine #
#######################################################
username=$(sed -n "/^$USER/p" /etc/passwd | awk -F ":" '{ print $1 }')
if [ "$username" == "$USER" ]; then
    echo "$USER already exists"
else
    useradd  -m -G wheel $USER
fi
chage -I -1 -m 0 -M 99999 -E -1 $USER

##############################################
# Check if satellite user has sudo privilege #
##############################################
if [ ! -f "$FILE2" ]; then
    touch $FILE2
    chown root:root $FILE2
    echo "$USER  ALL=(ALL) NOPASSWD: ALL" > $FILE2
    chmod 440 $FILE2
else
    echo "$FILE2 already exists"
fi

###################################################################
# Create ssh key directory and authorized keys files to store key #
###################################################################
if [ ! -d "$FILE3" ]; then
    mkdir $FILE3
    touch $FILE1
    chown -R $USER:$USER $FILE3
    chmod 700 $FILE3
    chmod 600 $FILE1

elif [ ! -f "$FILE1" ]; then
    touch $FILE1
    chmod 600 $FILE1
    chmod 700 $FILE3
    chown -R $USER:$USER $FILE3
    chown $USER:$USER $FILE1
else
    echo "Both $FILE1 and $FILE3 already exists"
fi

#########################################
# Copy foreman user ssh keys to clients #
#########################################
curl --connect-timeout 5 -k https://$BESTHOST:9090/ssh/pubkey > /home/$USER/.ssh/authorized_keys
if [ $? -eq 0 ]; then
    echo "ssh keys successfully copied to client"
else
    echo "Error: command failed!"
fi
sudo subscription-manager config --rhsm.manage_repos=1

#########################################
# Prepare Centrify but don't install it #
#########################################
FN=$(wget -qO - https://$BESTHOST/pub | grep -o "\b[^ ]*delinea[^ ]*\b" )
/bin/rm -rf cent* Cent*
wget -O $FN  https://$BESTHOST/pub/$FN
mkdir cent
cd cent
tar  -xf ../$FN
echo "Finished"
exit
