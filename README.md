# hub-dash-site-builder

This repository creates a docker container used by [hubverse-org/hub-dashboard-control-room](https://github.com/hubverse-org/hub-dashboard-control-room)
to generate a static site that contains a forecast dashboard and other
customizations. 

This container works on a repository created from the [dashboard
template](https://github.com/hubverse-org/hub-dashboard-template) that assumes
one of the following is true if the predevals and predtimechart configuration
files are present:

1. (default) your _public GitHub dashboard repository_ has two orphan branches
   called `ptc/data` and `predevals/data` containing data sources for the
   visualizations OR
2. you have copies of these data sources in individual folders locally in your
   repository.

If you do not have either of the predtimechart or predevals configuration files
present, then these data are not necessary.

The static site is generated via [`render.sh`](./render.sh) inside the
container and writes a folder called `_site/` under the `pages/` folder of the
dashboard repository. You need to then copy the contents of `_site/` into the
`gh-pages` branch of a dashboard repository.


## Usage

To get help, you can run the container with the `--help` argument, which will
print the usage and display [examples](examples.md).

> [!NOTE]
>
> The default working directory inside the container, set in the image using `WORKDIR`, is `/site`. This is where we expect the dashboard source and its subfolders to live, and where all commands are executed unless a different working directory is specified

The general workflow can be run like so:

1. clone the dashboard repository
2. pull the latest container:
   ```bash
   docker pull ghcr.io/hubverse-org/hub-dash-site-builder:latest
   ```
4. Run the container (replace `/path/to/dashboard/repo` with the absolute path
   to your dashboard. This can be replaced with `$(pwd)` to use the current
   working directory):
   ```bash
   docker run \
   --platform=linux/amd64 \
   --rm \
   -ti \
   -v "/path/to/dashboard/repo":"/site" \
   ghcr.io/hubverse-org/hub-dash-site-builder:latest \
   render.sh
   -u <owner>
   -r <repo>
   -o out
   ```
5. clone the gh-pages branch from the dashboard repository into a folder called `site/`
6. copy the files from the `/path/to/dashboard/out/` folder into `site/`
7. enter the `site/` folder and run `git push ` to push the changes.

### Rendering with local data

If you have local versions of the predtimechart and predevals data, then you
can build the site and store the copies in the site itself by using the -p and -e
flags:


```bash
docker run \
--platform=linux/amd64 \
--rm \
-ti \
-v "/path/to/dashboard/repo":"/site" \
ghcr.io/hubverse-org/hub-dash-site-builder:latest \
render.sh
-p <relative-path-to-predtimechart-data>
-e <relative-path-to-predevals-data>
-o out
```

## Testing

This docker container can be tested with the [`tests/run.sh`](tests/run.sh) script and
the flusight hub. These tests will clone a hub dashboard to a temporary file and
run tests on it. 


```sh
# Step 1 build the container
docker build --platform=linux/amd64 -t hdsb .
# Step 2 run the tests against an _active_ hub dashboard
bash tests/run.sh hdsb reichlab/flusight-dashboard
```
