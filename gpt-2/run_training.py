import warnings  # nopep8
warnings.simplefilter(action='ignore', category=FutureWarning)  # nopep8
import gpt_2_simple as gpt2
import argparse
import requests
import os

parser = argparse.ArgumentParser()

parser.add_argument('--model', '-m', type=str,
                    help='Which pretrained model (124M or 355M)', default="124M")
parser.add_argument('--model_dir', '-md', type=str,
                    help='Model directory', default="models")
parser.add_argument('--checkpoint', '-c', type=str,
                    help='Checkpoint directory', default="checkpoint")
parser.add_argument('--text', '-t', type=str,
                    help='Text file to fine tune model with', required=True)
parser.add_argument('--steps', '-s', type=int,
                    help='Training steps', default=1000)
parser.add_argument('--name', '-n', type=str,
                    help='Run name', required=True)

args = parser.parse_args()


model_name = args.model
model_dir = args.model_dir
file_name = args.text
training_steps = args.steps
run_name = args.name
checkpoint_dir = args.checkpoint


if not os.path.isdir(os.path.join(model_dir, model_name)):
    print(f"Downloading {model_name} model...")
    gpt2.download_gpt2(model_dir=model_dir, model_name=model_name)

sess = gpt2.start_tf_sess()
gpt2.finetune(sess, file_name, model_dir=model_dir, model_name=model_name, restore_from='fresh',
              steps=training_steps, run_name=run_name, checkpoint_dir=checkpoint_dir, sample_every=2000)
