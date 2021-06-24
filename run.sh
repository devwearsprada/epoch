#!/bin/bash

# get dotenv instagram username & password
IG_LOGIN=$(grep -v '^#' .env | grep -e "IG_USERNAME" | sed -e 's/.*=//')
IG_PASSWORD=$(grep -v '^#' .env | grep -e "IG_PASSWORD" | sed -e 's/.*=//')
ACCOUNTS=("patmcgrathreal" "tunameltsmyheart")
LENGTH=${#ACCOUNTS[@]}
COUNT=3000

i=0

while :
do
  if [ $i -ge $LENGTH ]; then
    # reset counter
    i=0
  fi

  ACCOUNT=${ACCOUNTS[i]}



  # download images from instagram
  echo "[INFO]: Downloading profile @${ACCOUNT}"
  python assets/dataset_downloader.py -a ${ACCOUNT} -o ./assets/datasets/${ACCOUNT}/ -c 3000 -q True


  echo "[INFO]: Resizing ${ACCOUNT} to ${ACCOUNT}-cropped"
  # create empty folder for cropped images
  if [ ! -d ./assets/datasets/${ACCOUNT}-cropped ]; then
    mkdir ./assets/datasets/${ACCOUNT}-cropped
  fi

    # remove images if amount is higher than count
  images=(./assets/datasets/stylegan2/${ACCOUNT}-cropped/*.jpg)
  totalImages=${#images[@]}
  x=0

  for image in ${images[@]}; do
    x=$(( x + 1 ))
    if [ $x -ge ${COUNT} ]; then
      rm -rf $image
    fi 
  done

  python ./assets/dataset_resize.py -i ./assets/datasets/${ACCOUNT}/ -o ./assets/datasets/${ACCOUNT}-cropped/ -d 512 512

  echo "[INFO]: Creating TFRecords of ${ACCOUNT}-cropped"
  # create .tfrecords for training
  python stylegan2/dataset_tool.py create_from_images ./assets/tfrecords/${ACCOUNT} ./assets/datasets/${ACCOUNT}-cropped

  echo "[INFO]: Training StyleGAN2 model based on @${ACCOUNT}"
  # create folder for training result
  if [ ! -d ./assets/results/stylegan2/${ACCOUNT} ]; then
    mkdir ./assets/results/stylegan2/${ACCOUNT}
  fi

  # training
  python stylegan2/run_training.py --num-gpus=1 --data-dir=./assets/tfrecords/ --config=config-f --dataset=${ACCOUNT} --mirror-augment=true --gamma=1000 --total-kimg 200 --result-dir=./assets/results/stylegan2/
  
  # increment counter
  ((i++))
done