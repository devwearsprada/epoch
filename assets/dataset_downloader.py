import os
from os.path import join, dirname
from datetime import datetime
import argparse
from dotenv import load_dotenv
from instaloader import Instaloader, Profile

dotenv_path = join(dirname(__file__), '.env')
load_dotenv(dotenv_path)

parser = argparse.ArgumentParser()

parser.add_argument('--account', '-a', type=str,
                    help='Instagram account to download', required=True)
parser.add_argument('--output', '-o', type=str,
                    help='Where to save the downloaded images', required=True)
parser.add_argument('--count', '-c', type=int,
                    help='Max image count', required=True)
parser.add_argument('--quiet', '-q', type=bool,
                    help='Max image count', default=False)
                    
args = parser.parse_args()

IG_USERNAME = os.environ.get("IG_USERNAME")
IG_PASSWORD = os.environ.get("IG_PASSWORD")

ACCOUNT = args.account
OUTPUT = args.output
COUNT = args.count
QUIET = args.quiet

L = Instaloader(quiet=QUIET)
# # login
if IG_USERNAME is not None and IG_PASSWORD is not None:
    # L.load_session_from_file(IG_USERNAME)
    L.login(IG_USERNAME, IG_PASSWORD)

profile = Profile.from_username(L.context, ACCOUNT)
posts = profile.get_posts()

filePath = '{}{}.txt'.format(OUTPUT, ACCOUNT)


if not os.path.exists(OUTPUT):
    os.makedirs(OUTPUT)

if os.path.exists(filePath):
    os.remove(filePath)
    

try:
    x = 0
    f = open(filePath, 'w+')

    for post in posts:
        if x >= COUNT:
            break
        if post.typename == 'GraphVideo' or post.typename == 'GraphSidecar':
            continue

        x += 1
        
        caption = post.caption
        f.write(caption)

        date = post.date_utc.strftime("%m.%d.%Y-%H:%M:%S")
        L.download_pic(filename="{}{}-{}".format(OUTPUT, ACCOUNT, date), url=post.url, mtime=datetime.now())

        print("[{}/{}]: @{} [{:35.35}...] ".format(x, COUNT, ACCOUNT, caption))
except KeyboardInterrupt:
    print("[INFO} User quitted")