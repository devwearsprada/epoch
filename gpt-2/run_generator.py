import warnings  # nopep8
warnings.simplefilter(action='ignore', category=FutureWarning)  # nopep8
import gpt_2_simple as gpt2
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('--checkpoint', '-c', type=str,
                    help='Checkpoint directory', default="checkpoint")
parser.add_argument('--name', '-n', type=str,
                    help='Run name', required=True)

args = parser.parse_args()

run_name = args.name
checkpoint_dir = args.checkpoint

sess = gpt2.start_tf_sess()
gpt2.load_gpt2(sess, run_name=run_name, checkpoint_dir=checkpoint_dir)

gpt2.generate(sess, run_name=run_name, checkpoint_dir=checkpoint_dir,
              prefix="Epoch is", temperature=1.0)
