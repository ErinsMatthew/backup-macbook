import argparse
import os
import hashlib

#
#  parse command-line arguments
#
parser = argparse.ArgumentParser()

parser.add_argument("directory")
parser.add_argument("-e", "--encoding", help="Set string encoding.", default="UTF-8")

args = parser.parse_args()

directory = os.fsencode(os.path.expanduser(args.directory))

#
#  hash to hold file information
#
files = {}

#
#  calculate hash and modified time for each file
#
for entry in os.scandir(directory):
    if entry.is_file():
        with open(entry, "rb") as f:
            md5 = hashlib.file_digest(f, "md5").hexdigest()

        if md5:
            if md5 not in files:
                files[md5] = [entry]
            else:
                files[md5].append(entry)

#
#  remove newest file for each hash
#
for md5 in list(files.keys()):
    files[md5].sort(key=lambda entry: os.stat(entry).st_mtime)

    files[md5].pop()

    # remove empty lists
    if len(files[md5]) == 0:
        del files[md5]

for md5 in list(files.keys()):
    for entry in list(files[md5]):
        os.remove(entry)

        print("Deleted {0}".format(entry.name.decode(args.encoding)))
