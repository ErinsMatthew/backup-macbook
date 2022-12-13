import os
import hashlib

files = {}

#
#  calculate hash and modified time for each file
#
directory = os.path.expanduser("~/OneDrive/Brewfiles")

for entry in os.scandir(directory):
    if entry.is_file():
        md5 = hashlib.md5(open(entry, 'rb').read()).hexdigest()

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

        print('Deleted {0}'.format(entry.name.decode('UTF-8')))
