import os
from datetime import datetime
import argparse
from instaloader import Instaloader, Profile

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

ACCOUNT = args.account
OUTPUT = args.output
COUNT = args.count
QUIET = args.quiet

L = Instaloader(quiet=QUIET)
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
        L.download_pic(filename="{}-{}-{}".format(OUTPUT, ACCOUNT, date), url=post.url, mtime=datetime.now())

        print("[{}/{}]: @{} [{:35.35}...] ".format(x, COUNT, ACCOUNT, caption))
except KeyboardInterrupt:
    print("[INFO} User quitted")