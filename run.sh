#!/bin/bash
cd "$(dirname "$0")"

# activate conda env
source /home/epoch/anaconda3/etc/profile.d/conda.sh
conda activate epoch

ENV_PYTHON=/home/epoch/anaconda3/envs/epoch/bin/python
ACCOUNTS=("patmcgrathreal" "tunameltsmyheart" "gymshark")
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
  #echo "[INFO]: Downloading profile @${ACCOUNT}"
  #python assets/dataset_downloader.py -a ${ACCOUNT} -o ./assets/datasets/${ACCOUNT}/ -c 3000 -q True

  echo "[INFO]: Resizing ${ACCOUNT} to ${ACCOUNT}-cropped"
  # create empty folder for cropped images
  if [ ! -d ./assets/datasets/${ACCOUNT}-cropped ]; then
     mkdir ./assets/datasets/${ACCOUNT}-cropped
   fi
  # resize images
  python ./assets/dataset_resize.py -i ./assets/datasets/${ACCOUNT}/ -o ./assets/datasets/${ACCOUNT}-cropped/ -d 512 512

  echo "[INFO]: Creating TFRecords of ${ACCOUNT}-cropped"
  # create .tfrecords for training
  python stylegan2/dataset_tool.py create_from_images ./assets/tfrecords/${ACCOUNT} ./assets/datasets/${ACCOUNT}-cropped

  echo "[INFO]: Copying captions to ${ACCOUNT}.txt"
  # create dataset for GPT model
  empty=true
  for filename in ./assets/datasets/${ACCOUNT}/*.txt; do
    if [ "$empty" = true ]; then
      > ./assets/datasets/gpt-2/${ACCOUNT}.txt
      empty=false
    fi
    cat ${filename} >> ./assets/datasets/gpt-2/${ACCOUNT}.txt
  done

  echo "[INFO]: Training GPT-2 model based on @${ACCOUNT}"
  python ./gpt-2/run_training.py -m 355M -md ./gpt-2/models -t ./assets/datasets/gpt-2/${ACCOUNT}.txt -s 200 -c ./gpt-2/checkpoint -n ${ACCOUNT}

  echo "[INFO]: Generating GPT-2 sample"
  python gpt-2/run_generator.py -c ./gpt-2/checkpoint -n ${ACCOUNT}
  CAPTION=$( cat ./assets/results/gpt-2/${ACCOUNT}.txt)

  echo "[INFO]: Training StyleGAN2 model based on @${ACCOUNT}"
  # create folder for training result
  if [ ! -d ./assets/results/stylegan2/${ACCOUNT} ]; then
    mkdir ./assets/results/stylegan2/${ACCOUNT}
  fi
  # training
  python stylegan2/run_training.py --num-gpus=1 --data-dir=./assets/tfrecords/ --config=config-f --dataset=${ACCOUNT} --mirror-augment=true --gamma=1000 --total-kimg 1 --result-dir=./assets/results/stylegan2/

  echo "[INFO]: Generating new @${ACCOUNT} image"
  python stylegan2/run_generator.py generate-images --network ./assets/results/stylegan2/${ACCOUNT}/network-final.pkl --seeds $(( ( RANDOM % 9999 ) + 1)) --result-dir=./assets/results/stylegan2/

  echo "[INFO]: Uploading generated ${ACCOUNT} to /fakes"
  curl -F title=epoch -F caption="$CAPTION" -F image=@./assets/results/stylegan2/${ACCOUNT}/generated.png -F account=${ACCOUNT} https://epoch-api.glowie.dev/generated

  # increment counter
  ((i++))
done
