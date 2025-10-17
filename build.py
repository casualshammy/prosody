import os
import argparse
from build_common import git, docker, utils

dockerRepo = os.getenv('DOCKER_REPO')
if not dockerRepo:
  raise Exception("DOCKER_REPO environment variable is not set")

dockerLogin = os.getenv('DOCKER_LOGIN')
if not dockerLogin:
  raise Exception("DOCKER_LOGIN environment variable is not set")

dockerPassword = os.getenv('DOCKER_PASSWORD')
if not dockerPassword:
  raise Exception("DOCKER_PASSWORD environment variable is not set")

argParser = argparse.ArgumentParser()
argParser.add_argument('--platform', type=str, required = True)
args = argParser.parse_args()
platform: str = args.platform

version = f"{git.get_version_from_current_branch()}.{git.get_last_commit_index()}"

print(f"===========================================", flush=True)
print(f"Creating docker image...", flush=True)
print(f"Version: '{version}'", flush=True)
print(f"===========================================", flush=True)
docker.buildPush(f"{dockerRepo}:{version}-{platform}", f"Dockerfile", dockerLogin, dockerPassword)
docker.buildPush(f"{dockerRepo}:latest-{platform}", f"Dockerfile", dockerLogin, dockerPassword)

print(f"===========================================", flush=True)
print(f"Done!", flush=True)
print(f"===========================================", flush=True)

git.create_tag_and_push(version, "origin", "casualshammy", True)
utils.callThrowIfError("git stash", True)
git.merge("main", git.get_current_branch_name(), True, "casualshammy", True)