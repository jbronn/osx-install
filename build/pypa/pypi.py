#!/usr/bin/python3
import json
import sys

if __name__ == '__main__':
    try:
        version = sys.argv[1]
    except:
        sys.stdout.write('Must provide the desired version.\n')
        sys.exit(1)

    try:
        package_info = json.loads(sys.stdin.read())
    except:
        sys.stdout.write('Cannot load the package info JSON.\n')
        sys.exit(1)

    if not version in package_info['releases']:
        sys.stdout.write('Cannot find the given version.\n')
        sys.exit(1)

    for package in package_info['releases'][version]:
        if package['packagetype'] == 'bdist_wheel':
            sys.stdout.write('{}\n'.format(package['url']))
            sys.exit(0)

    sys.stdout.write('Cannot find wheel download from the JSON.\n')
