import os
import requests
import argparse
import gpt_2_simple as gpt2

parser = argparse.ArgumentParser()

parser.add_argument('--model', '-m', type=str,
                    help='Which pretrained model (124M or 355M)', default="124M")
parser.add_argument('--text', '-t', type=str,
                    help='Text file to fine tune model with', required=True)
parser.add_argument('--steps', '-s', type=int,
                    help='Training steps', default=1000)

args = parser.parse_args()


model_name = args.model
file_name = args.text
training_steps = args.steps

if not os.path.isdir(os.path.join("models", model_name)):
	print(f"Downloading {model_name} model...")
	gpt2.download_gpt2(model_name=model_name)

sess = gpt2.start_tf_sess()
gpt2.finetune(sess, file_name, model_name, steps=training_steps)