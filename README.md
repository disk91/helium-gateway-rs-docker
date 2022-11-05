# Docker GatewayRS for hosting multiple gateways on a single server

This project allows to build Helium gateway-rs (data-only hotspot) as a docker container on x86_64. The objective is to migrate field existing LoRaWan gateway to Helium network in a simple way. 

The LoRaWAN gateway will just send its traffic using the Semtech Legacy protocol to a hosted server running the gateway-rs software. 

Using Docker it is possible to host many gateway-rs software on a single server that way the migration of multiple LoRaWAN gateway will be made at low cost.

## build container

```bash
docker build -t gateway-rs .
```

## run a new instance

```bash
./run.sh -c ../rs/gw1 -p 5000 -z EU868 -o 13ZhVBrEJLAaHKQ2vKZPFAxyAMqxd2726UhSFzDWXpGEizSUixU --update false
Initializing gateway rs
Setting up Zone for EU868
Setting up auto update status false
{
  "address": "144enMRzNd5eKmhbP4KoGCQ9n...",
  "name": "tricky-la..."
}
{
  "address": "144enMRzNd5eKmhbP4...",
  "fee": 65000,
  "mode": "dataonly",
  "owner": "13ZhVBrEJLAaHKQ2vKZP...",
  "payer": "13ZhVBrEJLAaHKQ2vKZP...",
  "staking fee": 1000000,
  "txn": "CrMBCiEBUaMXgAYlsKmAUE0UpkGjD5+5+LbD38cAdEIhsD8o4qcSIQGTYReE9yDRVPqsxtwU1qKY6e6aV6NwXrkH..."
}
```

It prints the registration transaction and the name of the gateway. this transaction can be used to register the hotspot.

The container name is integrating the configuration path to easily find it. The configuration is saved in the configuration directory if you need to do some manual modification.

**Please backup the gateway_key.bin file located in the configuration directory to be able to recreate you gateway in case of data loss**

### register the hotspot on the blockchain

Now you need to make the hotspot registration, using the helium wallet cli corresponding to the owner/payer previously setup
```
./helium-wallet hotspots add <txn obtained previously> --commit
```

Then you need to give it a location
```
./helium-wallet hotspots assert --gateway <GATEWAY_ADRESSS_ID> --lat XX.XXXX --lon Y.YYYY  --mode dataonly --commit
```

## restart an instance

If you need to restart the docker container, you just need to specify the path to the configuration:


```bash
./run.sh -c ../rs/gw1
```
