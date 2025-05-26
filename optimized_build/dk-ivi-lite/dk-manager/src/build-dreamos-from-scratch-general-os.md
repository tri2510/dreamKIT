# Build DreamOS from Scratch for general enviroment


## 1. Install Docker
Run the following command to uninstall all conflicting packages:
```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
```
`apt-get` might report that you have none of these packages installed.

Images, containers, volumes, and networks stored in /var/lib/docker/ aren't automatically removed when you uninstall Docker. If you want to start with a clean installation, and prefer to clean up any existing data, read the [uninstall Docker Engine](https://docs.docker.com/engine/install/ubuntu/#uninstall-docker-engine) section.

```
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

Make docker access rootless by this cmd
```
sudo apt-get install -y uidmap
dockerd-rootless-setuptool.sh install
```

[INFO] Make sure the following environment variable(s) are set (or add them to ~/.bashrc):
```
export PATH=/usr/bin:$PATH
```

[INFO] Some applications may require the following environment variable too:
```
export DOCKER_HOST=unix:///run/user/1000/docker.sock
```

Test docker with this cmd:

```
sudo docker run hello-world
```


## 2. Install Dapr

```
wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash
dapr init
```
Configure mqtt pubsub in dapr
```
cd ~/.dapr/components/
cp pubsub.yaml pubsub.yaml.bk
```

replace all the content of pubsub.yaml with the content below,
```
nano pubsub.yaml
```
```
apiVersion: dapr.io/v1alpha1
kind: Component
metadata:
  name: mqtt-pubsub
  namespace: default
spec:
  type: pubsub.mqtt
  version: v1
  metadata:
  - name: url
    value: "mqtt://localhost:1883"
  - name: qos
    value: 1
  - name: retain
    value: "false"
  - name: cleanSession
    value: "false"
```

Finally run dapr dashboard at port 12345
```
dapr dashboard -p 12345 &
```
## 3. Prepare vss.json for Kuksa DataBroker
```
mkdir -p ~/vss
cd ~/vss
sudo apt install python-is-python3
sudo apt install python3-pip
pip install anytree deprecation graphql-core stringcase setuptools
cd ~/vss/vehicle_signal_specification/vss-tools
python vspec2json.py -I ../spec -u ../spec/units.yaml ../spec/VehicleSignalSpecification.vspec vss.json
```

Copy vss.json file to ~/vss dir
```
cp ~/vss/vehicle_signal_specification/vss-tools/vss.json ~/vss/vss.json
```

If it runs successfully, we shall see the output as follows:
```
INFO Output to json format
INFO Known extended attributes:
INFO Added 56 units from ../spec/units.yaml
INFO Loading vspec from ../spec/VehicleSignalSpecification.vspec...
INFO Calling exporter...
INFO Generating JSON output...
INFO Serializing compact JSON...
INFO All done.
```
And the output file shall be created at `~/vss/vehicle_signal_specification/vsstools/vss.json`

## 4. Install core velocitas python libs

```
pip install cloudevents
```
// install velocitas app sdk - this might take quite a long time.
```
pip install git+https://github.com/eclipse-velocitas/vehicle-app-python-sdk.git@v0.9.2
ln -s ~/.local/lib/python3.10/site-packages/sdv ~/.local/lib/python3.10/site-packages/velocitas_sdk
```
- If it runs OK, it should create ~/.local/lib/python3.10/site-packages/sdv
- Note: apply below pip install if there is some relevant error
```
pip install setuptools==59.5.0
```
```
pip install git+https://github.com/eclipse-velocitas/vehicle-model-python.git@v0.3.0
```
- If it runs OK, it should create `~/.local/lib/python3.10/site-packages/sdv_model`
// make a link from sdv_model, this shall be used by vehicle app from digital.auto
```
ln -s ~/.local/lib/python3.10/site-packages/sdv_model ~/.local/lib/python3.10/site-packages/vehicle
```

## 5. Run local runtime environment
#### run mqtt server
```
docker run --rm --init --name mqtt-broker -p 1883:1883 -p 9001:9001 --network host eclipse-mosquitto:2.0.14 mosquitto -c /mosquitto-no-auth.conf &
```
#### run databroker

```
export HOME_PATH=~
dapr run --app-id vehicledatabroker --app-protocol grpc --resources-path $HOME_PATH/.dapr/components --config $HOME_PATH/.dapr/config.yaml --app-port 55555 -- docker run --rm --init --name vehicledatabroker -e KUKSA_DATA_BROKER_METADATA_FILE=$HOME_PATH/vss/vss.json -e KUKSA_DATA_BROKER_PORT=55555 -e 50001 -e 3500 -v $HOME_PATH/vss/vss.json:$HOME_PATH/vss/vss.json --network host ghcr.io/eclipse/kuksa.val/databroker:0.3.0 &
```

## 6. Test and verify

### Test with kuksa-client
```
pip install kuksa-client
```

The try it
- For kuksa-client ver >0.4.0
```
kuksa-client grpc://127.0.0.1:55555
```
- For kuksa-client ver 0.4.0
```
kuksa-client --ip 127.0.0.1 --port 55555 --protocol grpc --insecure
```

### Test with vehicle-app-python-template
```
export HOME_PATH=~
cd  ~/vss
git clone https://github.com/eclipse-velocitas/vehicle-app-python-template.git
cd vehicle-app-python-template/
pip install -r requirements.txt
```
// start app
```
dapr run --app-id testapp --app-protocol grpc --resources-path $HOME_PATH/.dapr/components --config $HOME_PATH/.dapr/config.yaml --app-port 50008 python3 app/src/main.py
```
