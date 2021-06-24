#!/bin/bash

# get dotenv instagram username & password
IG_LOGIN=$(grep -v '^#' .env | grep -e "IG_USERNAME" | sed -e 's/.*=//')
IG_PASSWORD=$(grep -v '^#' .env | grep -e "IG_PASSWORD" | sed -e 's/.*=//')
ACCOUNTS=("patmcgrathreal" "tunameltsmyheart")
LENGTH=${#ACCOUNTS[@]}

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
  if [ -z "$IG_LOGIN" ] || [ -z "$IG_PASSWORD" ]; then
    instaloader ${ACCOUNT} --no-videos --no-video-thumbnails --no-metadata-json --no-compress-json --no-profile-pic --dirname-pattern=./assets/datasets/stylegan2/{profile} --abort-on=302,400,429
  else
    instaloader ${ACCOUNT} --no-videos --no-video-thumbnails --no-metadata-json --no-compress-json --no-profile-pic --dirname-pattern=./assets/datasets/stylegan2/{profile} --login=${IG_LOGIN} --password=${IG_PASSWORD} --sessionfile ./.sessions/${IG_LOGIN}
  fi

  echo "[INFO]: Creating ${ACCOUNT}.txt"
  # create dataset for GPT model
  empty=true
  for filename in ./assets/datasets/stylegan2/${ACCOUNT}/*.txt; do
    if [ "$empty" = true ]; then
      > ./assets/datasets/gpt-2/${ACCOUNT}.txt
      empty=false
    fi 

    cat ${filename} >> ./assets/datasets/gpt-2/${ACCOUNT}.txt
  done

  echo "[INFO]: Resizing ${ACCOUNT} to ${ACCOUNT}-cropped"
  # create empty folder for cropped images
  if [ ! -d ./assets/datasets/stylegan2/${ACCOUNT}-cropped ]; then
    mkdir ./assets/datasets/stylegan2/${ACCOUNT}-cropped
  fi

  python ./assets/dataset_resize.py -i ./assets/datasets/stylegan2/${ACCOUNT}/ -o ./assets/datasets/stylegan2/${ACCOUNT}-cropped/ -d 512 512

  echo "[INFO]: Creating TFRecords of ${ACCOUNT}-cropped"
  # create .tfrecords for training
  python stylegan2/dataset_tool.py create_from_images ./assets/tfrecords/${ACCOUNT} ./assets/datasets/stylegan2/${ACCOUNT}-cropped

  echo "[INFO]: Training StyleGAN2 model based on @${ACCOUNT}"
  # create folder for training result
  if [ ! -d ./assets/results/stylegan2/${ACCOUNT} ]; then
    mkdir ./assets/results/stylegan2/${ACCOUNT}
  fi

  # training
  python stylegan2/run_training.py --num-gpus=1 --data-dir=./assets/tfrecords/ --config=config-f --dataset=${ACCOUNT} --mirror-augment=true --gamma=1000 --total-kimg 200
  # increment counter
  ((i++))
done