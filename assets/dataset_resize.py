import os
import argparse
from PIL import Image


parser = argparse.ArgumentParser()

parser.add_argument('--input', '-i', type=str,
                    help='Directory containing the images that need to be resized', required=True)
parser.add_argument('--output', '-o', type=str,
                    help='Where to save the resized images', required=True)
parser.add_argument('--dimensions', '-d', type=int, nargs='+',
                    help='Dimensions for width and height. Example: 512 512', required=True)
args = parser.parse_args()

DIRECTORY = args.input
SAVE_DIR = args.output
DIMENSIONS = tuple(args.dimensions)


def resize_and_crop(img_path, modified_path, size, crop_type='middle'):
    """
    Resize and crop an image to fit the specified size.

    args:
    img_path: path for the image to resize.
    modified_path: path to store the modified image.
    size: `(width, height)` tuple.
    crop_type: can be 'top', 'middle' or 'bottom', depending on this
    value, the image will cropped getting the 'top/left', 'middle' or
    'bottom/right' of the image to fit the size.
    raises:
    Exception: if can not open the file in img_path of there is problems
    to save the image.
    ValueError: if an invalid `crop_type` is provided.
    """
    # If height is higher we resize vertically, if not we resize horizontally
    img = Image.open(img_path)
    # Get current and desired ratio for the images
    img_ratio = img.size[0] / float(img.size[1])
    ratio = size[0] / float(size[1])
    # The image is scaled/cropped vertically or horizontally depending on the ratio
    if ratio > img_ratio:
        img = img.resize((size[0], int(round(size[0] * img.size[1] / img.size[0]))),
                         Image.ANTIALIAS)
        # Crop in the top, middle or bottom
        if crop_type == 'top':
            box = (0, 0, img.size[0], size[1])
        elif crop_type == 'middle':
            box = (0, int(round((img.size[1] - size[1]) / 2)), img.size[0],
                   int(round((img.size[1] + size[1]) / 2)))
        elif crop_type == 'bottom':
            box = (0, img.size[1] - size[1], img.size[0], img.size[1])
        else:
            raise ValueError('ERROR: invalid value for crop_type')
        img = img.crop(box)
    elif ratio < img_ratio:
        img = img.resize((int(round(size[1] * img.size[0] / img.size[1])), size[1]),
                         Image.ANTIALIAS)
        # Crop in the top, middle or bottom
        if crop_type == 'top':
            box = (0, 0, size[0], img.size[1])
        elif crop_type == 'middle':
            box = (int(round((img.size[0] - size[0]) / 2)), 0,
                   int(round((img.size[0] + size[0]) / 2)), img.size[1])
        elif crop_type == 'bottom':
            box = (img.size[0] - size[0], 0, img.size[0], img.size[1])
        else:
            raise ValueError('ERROR: invalid value for crop_type')
        img = img.crop(box)
    else:
        img = img.resize((size[0], size[1]),
                         Image.ANTIALIAS)
    # If the scale is the same, we do not need to crop
    img.save(modified_path, quality=100, subsampling=0)


for file in os.listdir(DIRECTORY):
    if file.endswith(".jpg") or file.endswith(".jpeg") or file.endswith("png") or file.endswith(".JPEG") or file.endswith(".JPG") or file.endswith("PNG"):
        resize_and_crop(DIRECTORY + file, SAVE_DIR + file, DIMENSIONS)
