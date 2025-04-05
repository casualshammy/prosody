import os
from build_common import git, docker, utils

dockerRepo = os.getenv('DOCKER_REPO')
dockerLogin = os.getenv('DOCKER_LOGIN')
dockerPassword = os.getenv('DOCKER_PASSWORD')

version = f"{git.get_version_from_current_branch()}.{git.get_last_commit_index()}"

print(f"===========================================", flush=True)
print(f"Creating docker image...", flush=True)
print(f"Version: '{version}'", flush=True)
print(f"===========================================", flush=True)
docker.buildPush(f"{dockerRepo}:{version}", f"Dockerfile", dockerLogin, dockerPassword)
docker.buildPush(f"{dockerRepo}:latest", f"Dockerfile", dockerLogin, dockerPassword)

print(f"===========================================", flush=True)
print(f"Done!", flush=True)
print(f"===========================================", flush=True)

git.create_tag_and_push(version, "origin", "casualshammy", True)
utils.callThrowIfError("git stash", True)
git.merge("main", git.get_current_branch_name(), True, "casualshammy", True)