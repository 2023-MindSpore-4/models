#!/bin/bash
# Copyright 2021 Huawei Technologies Co., Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ============================================================================

if [ $# != 3 ] && [ $# != 4 ]
then 
    echo "Usage: bash run_distribute_train_gpu.sh [cifar10|imagenet2012] [CONFIG_PATH] [DATASET_PATH] [PRETRAINED_CKPT_PATH](optional)"
    exit 1
fi

if [ $1 != "cifar10" ] && [ $1 != "imagenet2012" ]
then 
    echo "error: the selected dataset is neither cifar10 nor imagenet2012"
    exit 1
fi

get_real_path(){
  if [ "${1:0:1}" == "/" ]; then
    echo "$1"
  else
    echo "$(realpath -m $PWD/$1)"
  fi
}

PATH1=$(get_real_path $3)

if [ $# == 4 ]
then 
    PATH2=$(get_real_path $4)
fi

if [ ! -d $PATH1 ]
then 
    echo "error: DATASET_PATH=$PATH1 is not a directory"
    exit 1
fi 

if [ $# == 4 ] && [ ! -f $PATH2 ]
then
    echo "error: PRETRAINED_CKPT_PATH=$PATH2 is not a file"
    exit 1
fi

ulimit -u unlimited
export DEVICE_NUM=4
export RANK_SIZE=4

rm -rf ./train_parallel
mkdir ./train_parallel
cp ../*.py ./train_parallel
cp ../*.yaml ./train_parallel
cp *.sh ./train_parallel
cp -r ../src ./train_parallel
cd ./train_parallel || exit

if [ $# == 3 ]
then
  mpirun --allow-run-as-root -n $RANK_SIZE --output-filename log_output --merge-stderr-to-stdout \
         python train.py --config_path=$2 --dataset=$1 --run_distribute=True \
         --device_num=$DEVICE_NUM --dataset_path=$PATH1 &> log.txt &
fi

if [ $# == 4 ]
then
  mpirun --allow-run-as-root -n $RANK_SIZE --output-filename log_output --merge-stderr-to-stdout \
        python train.py --config_path=$2 --dataset=$1 --run_distribute=True \
        --device_num=$DEVICE_NUM --dataset_path=$PATH1 --pre_trained=$PATH2 &> log.txt &
fi
