# hub-dash-site-builder

This repository creates a docker container used by [hubverse-org/hub-dashboard-control-room](https://github.com/hubverse-org/hub-dashboard-control-room)
to generate a static site that contains a forecast dashboard and other
customizations. 

The static site is generated via [`render.sh`](./render.sh) inside the
container and writes a folder called `_site/` under the `pages/` folder of the
dashboard repository. You need to then copy the contents of `_site/` into the
`gh-pages` branch of a dashboard repository.


1. clone the dashboard repository
2. Run the container:
   ```bash
   $ docker run \
     --platform=linux/amd64 \
     --rm \
     --ti \
     -v "/path/to/dashboard/repo":"/site" \
     ghcr.io/hubverse-org/hub-dash-site-builder:main \
     bash render.sh \
       ${dashboard repo org} \
       ${dashboard repo name} \
       "ptc/data"
   ```
3. clone the gh-pages branch of the dashboard repository into `pages/`
4. copy the files from the `dashboard repo/site/pages/_site/` folder into `pages/`
5. push the `pages/` folder up. 

