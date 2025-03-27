The examples below will demonstrate how to build a website locally using
both remote and local data. We will use the flusight dashboard website
repository for this example. In both examples, the site will appear
in the `pages/_site/` folder

```
# setup: clone the dashboard repository
git clone https://github.com/reichlab/flusight-dashboard.git
cd flusight-dashboard
```

Specify owner and repo to generate a website that pulls data from GitHub
```
docker run --platform=linux/amd64 --rm -it -v "$(pwd)":"/site" \
  render.sh -u reichlab -r flusight-dashboard -o remote
# serve the site (and view in your browser by going to localhost:8080)
python -m http.server 8080 -d remote
```

Specify local data folders to generate a standalone website that can be
be used offline.

```
# additional setup: add worktrees for the data branches

git worktree add --checkout data/ptc ptc/data
# Preparing worktree (checking out 'ptc/data')
# HEAD is now at 112a3ad update forecast data

git worktree add --checkout data/evals predevals/data
# Preparing worktree (checking out 'predevals/data')
# HEAD is now at 5237418 update score data
```

Now that the data are available locally, you can render the local version

```
docker run --platform=linux/amd64 --rm -it -v "$(pwd)":"/site" \
  render.sh -p data/ptc -e data/evals -o local
# serve the site (and view in your browser by going to localhost:8080)
python -m http.server 8080 -d local
```

Note that the local version will be much larger than the remote version. When
you are done with the local version, you can remove the `data/` directory and
run:

```
rm -rf data/
git worktree prune -v
# Removing worktrees/evals: gitdir file points to non-existent location
# Removing worktrees/ptc: gitdir file points to non-existent location
```
