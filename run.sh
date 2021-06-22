#!/bin/bash

# get dotenv instagram username & password
IG_LOGIN=$(grep -v '^#' .env | grep -e "IG_USERNAME" | sed -e 's/.*=//')
IG_PASSWORD=$(grep -v '^#' .env | grep -e "IG_PASSWORD" | sed -e 's/.*=//')
ACCOUNTS=("mrpimpgoodgame" "tunameltsmyheart" "patmcgrathreal")
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
  echo "[INFO]: Downloading profile ${ACCOUNT}"
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

  echo "[INFO]: Resizing ${ACCOUNT} to ${}-cropped"
  # create empty folder for cropped images
  if [ ! -d ./assets/datasets/stylegan2/${ACCOUNT}-cropped ]; then
    mkdir ./assets/datasets/stylegan2/${ACCOUNT}-cropped
  fi

  python ./assets/dataset_resize.py -d ./assets/datasets/stylegan2/${ACCOUNT}/ -s ./assets/datasets/stylegan2/${ACCOUNT}-cropped/

  # increment counter
  ((i++))
done