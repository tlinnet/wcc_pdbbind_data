# wcc_pdbbind_data

Make alias to Docker. Point to the folder where the pdbbind data is.

```bash
alias drd='docker run -ti --rm -p 8888:8888 -v "${HOME}/software/wcc_pdbbind_data":/home/jovyan/work --name rdock $USER/rdock'
```

## Then write commands for list with 5 PDB

```bash
# Make standard with 3 runs
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt

# With 5 runs 
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt n 5

# With 5 runs, and force write -w and force execute -w
drd ./00_execute_pdb_list.sh -p 00_5_pdb.txt -w -e n 5
```

## Then execute commands with GNU parallel

```bash
drd ./commands_run.sh
```

## Get the timings

```bash
drd ./10_get_timings.sh -p 00_all_pdb.txt 
```

## Clean up files

```bash
drd ./11_clean_files.sh -p 00_5_pdb.txt
drd ./11_clean_files.sh -p 00_all_pdb.txt
```

# Run docker image on google cloud

* https://cloud.google.com/compute/docs/containers/deploying-containers
* https://console.cloud.google.com/compute/instances

## Create VM

* create
  * Region: europe-west1 (Belgium)
  * Zone: europe-west1-b
  * Machine type: n1-highcpu-4   (80$/mo)
  * Container: Yes, deploy a container image
  * Container image: tlinnet/rdock
  * Standard persistent disk: 30 GB
  * Allow HTTP traffic: Yes
  * Allow HTTPS traffic: Yes
  * Management, disks, networking, SSH keys
    * Add from $HOME/.ssh/id_rsa.pub

## SSH to box

```bash
EXTIP=35.195.xxx.xxx

ssh $USER@$EXTIP
```

## Inspect docker

The system will automatically start downloading the image.
Until completed, this will be shown

```bash
docker ps
```
```bash
CONTAINER ID IMAGE                   
8e40cf2035bd gcr.io/gce-containers/konlet:v..... 
```

## Stop running image

Inspect

```bash
docker images
docker ps -a
```

```bash
#stop all containers:
docker kill $(docker ps -q)

#remove all containers
docker rm $(docker ps -a -q)
```

## Run Jupyter Notebook

Use this alias

```bash
alias drd='docker run -ti --rm -p 80:8888 -v "${HOME}/software/wcc_pdbbind_data":/home/jovyan/work --name rdock tlinnet/rdock'
```

Then run it

```bash
drd
```

Then in terminal will be

```bash
Copy/paste this URL into your browser when you connect for the first time,
to login with a token:
    http://localhost:8888/?token=1e82844a251f85aceb6e868e6806d760d9d9b257c77b6348
```

In a webbrowser, write (without https, just http)

```bash
35.195.xxx.xxx/?token=1e82844a251f85aceb6e868e6806d760d9d9b257c77b6348
```
