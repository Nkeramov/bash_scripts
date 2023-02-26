#!/bin/bash -i

download_cmd="wget"
download_threads_count=5

NIFI_VERSION="1.20.0"

if ! command -v aria2c &> /dev/null
then
    echo "aria2c is not installed, wget will be used for downloads"

else
    echo "aria2c is installed and will be used for downloads"
    download_cmd="aria2c -x${download_threads_count} --summary-interval=0"
fi

# download and extract ni-fi, nifi-registry, nifi-toolkit

cd ~
dirname=$(uuidgen)
mkdir ${dirname}
cd ${dirname}
echo "current dirname is $(pwd)"
printf "\n" >> ~/.profile
echo -n "========================= Downloading and extracting Apache NiFi =========================="
eval "${download_cmd} https://dlcdn.apache.org/nifi/${NIFI_VERSION}/nifi-${NIFI_VERSION}-bin.zip"
unzip -q nifi-${NIFI_VERSION}-bin.zip -d /opt/
echo "export NIFI_HOME=/opt/nifi-${NIFI_VERSION}" >> ~/.profile

echo -n "===================== Downloading and extracting Apache NiFi Registry ====================="
eval "${download_cmd} https://dlcdn.apache.org/nifi/$NIFI_VERSION/nifi-registry-${NIFI_VERSION}-bin.zip"
unzip -q nifi-registry-${NIFI_VERSION}-bin.zip -d /opt/
echo "export NIFI_REGISTRY_HOME=/opt/nifi-registry-${NIFI_VERSION}" >> ~/.profile

echo -n "====================== Downloading and extracting Apache NiFi Toolkit ====================="
eval "${download_cmd} https://dlcdn.apache.org/nifi/$NIFI_VERSION/nifi-toolkit-${NIFI_VERSION}-bin.zip"
unzip -q nifi-toolkit-${NIFI_VERSION}-bin.zip -d /opt/
echo "export NIFI_TOOLKIT_HOME=/opt/nifi-toolkit-${NIFI_VERSION}" >> ~/.profile
printf "\n" >> ~/.profile

# If ni-fi and ni-fi registry are not installed as a service
printf "\n" >> ~/.bashrc
echo "alias NIFI_START=\"$NIFI_HOME/bin/nifi.sh start\"" >> ~/.bashrc
echo "alias NIFI_STOP=\"$NIFI_HOME/bin/nifi.sh stop\"" >> ~/.bashrc
echo "alias NIFI_RESTART=\"$NIFI_HOME/bin/nifi.sh restart\"" >> ~/.bashrc
echo "alias NIFI_STATUS=\"$NIFI_HOME/bin/nifi.sh status\"" >> ~/.bashrc
printf "\n" >> ~/.bashrc
echo "alias NIFI_REGISTRY_START=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh start\"" >> ~/.bashrc
echo "alias NIFI_REGISTRY_STOP=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh stop\"" >> ~/.bashrc
echo "alias NIFI_REGISTRY_RESTART=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh restart\"" >> ~/.bashrc
echo "alias NIFI_REGISTRY_STATUS=\"$NIFI_REGISTRY_HOME/bin/nifi-registry.sh status\"" >> ~/.bashrc
printf "\n" >> ~/.bashrc
source ~/.profile
source ~/.bashrc
cd ~
rm -rf ${dirname}

# Change default ui banner text
nifi_banner_text=LOCALHOST
sed -i "s/^[#]*\s*nifi.ui.banner.text=.*/nifi.ui.banner.text=${nifi_banner_text}/" "$NIFI_HOME/conf/nifi.properties"

filename="$NIFI_HOME/conf/bootstrap.conf"
# Change default JVM memory settings
nifi_min_memory="2G"
nifi_max_memory="4G"
sed -i "s/^[#]*\s*java.arg.2=.*/java.arg.2=-Xms${nifi_min_memory}/" $filename
sed -i "s/^[#]*\s*java.arg.3=.*/java.arg.3=-Xmx${nifi_max_memory}/" $filename

# Change default JVM timzezone (parameter may be missing)
key_name="java.arg.8"
key_value="-Duser.timezone=Etc/UTC"
if ! grep -R "^[#]*\s*${key_name}=.*" $filename > /dev/null; then
  echo "Appending '${key_name}' to '${filename}' because not found"
  printf "\n" >> $filename
  echo "$key_name=$key_value" >> $filename
else
  echo "SETTING because '${key_name}' found already"
  sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $filename
fi

# Change default JVM encodings (parameter may be missing)
key_name="java.arg.57"
key_value="-Dfile.encoding=UTF8"
if ! grep -R "^[#]*\s*${key_name}=.*" $filename > /dev/null; then
  echo "Appending '${key_name}' to '${filename}' because not found"
  printf "\n" >> $filename
  echo "$key_name=$key_value" >> $filename
else
  echo "SETTING because '${key_name}' found already"
  sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $filename
fi

# Fixed encodings for cyrillic symbols (parameter may be missing)
key_name="java.arg.58"
key_value="-Dcalcite.default.charset=utf-8"
if ! grep -R "^[#]*\s*${key_name}=.*" $filename > /dev/null; then
  echo "Appending '${key_name}' to '${filename}' because not found"
  printf "\n" >> $filename
  echo "$key_name=$key_value" >> $filename
else
  echo "SETTING because '${key_name}' found already"
  sed -i "s/^[#]*\s*${key_name}=.*/$key_name=$key_value/" $filename
fi

nifi_sensitive_key=$(openssl rand -hex 20)
echo "NiFi sensitive key = ${nifi_sensitive_key}"
eval "$NIFI_HOME/bin/nifi.sh set-sensitive-properties-key ${nifi_sensitive_key} &> /dev/null"

nifi_login=nifi
nifi_password=nifi_password

echo "NiFi login = ${nifi_login}"
echo "NiFi passsword = ${nifi_password}"
eval "$NIFI_HOME/bin/nifi.sh set-single-user-credentials ${nifi_login} ${nifi_password} &> /dev/null"

eval "$NIFI_HOME/bin/nifi.sh start &> /dev/null"
echo -n "Waiting for NiFi start ..."
k=1
kmax=30
nifi_link=""
while [[ $k -le $kmax ]] && [[ "$nifi_link" = "" ]]
do
        nifi_link=$(grep "org.apache.nifi.web.server.JettyServer https" $NIFI_HOME/logs/nifi-app*.log | tail -1 | grep -Eo '(http|https)://[^/"]+')
        echo -n '.'
        ((k=k+1))
        sleep 1
done
printf "\n"
echo "NiFi started at ${nifi_link}"
#echo "To get the username and password use the command: grep Generated $NIFI_HOME/logs/nifi-app*log"
