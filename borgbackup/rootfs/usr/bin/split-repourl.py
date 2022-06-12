#!/usr/bin/env python
import sys
import argparse


def repo_url_split(repo_url):
    user_host, _, path = repo_url.partition(":")
    user, _, host = user_host.rpartition("@")
    return user, host, path


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-H", "--host", action="store_true")
    parser.add_argument("-u", "--user", action="store_true")
    parser.add_argument("-p", "--path", action="store_true")
    parser.add_argument("repourl", help="The repo url, example: user@host:path/to/repo")
    args = parser.parse_args()

    user, host, path = repo_url_split(args.repourl)
    if args.host:
        print(host)
    elif args.user:
        print(user)
    elif args.path:
        print(path)
    else:
        print(user, host, path)
