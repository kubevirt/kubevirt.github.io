# KubeVirt.io Website

[![Build Status](https://travis-ci.org/kubevirt/kubevirt.github.io.svg?branch=master)](https://travis-ci.org/kubevirt/kubevirt.github.io)

## Contributing contents

We more than welcome contributions in the form of blog posts, pages and/or labs, reach out if you happen to have an idea or find an issue with our contents! [Here's our guidelines for contents](GUIDELINES.md).

## Test your changes in a local container

### Run a Jekyll container
- Clone repository, check out source branch and prepare the Jekyll site
  ```console
  git clone -b source https://github.com/kubevirt/kubevirt.github.io.git && cd kubevirt.github.io
  for i in .jekyll-cache _site; do mkdir ${i} && chmod 777 ${i}; done
  for i in Gemfile.lock; do touch ${i} && chmod 777 ${i}; done
  ```

- On a SELinux enabled OS:

  ```console
  podman run -it --rm --name kubevirtio -p 4000:4000 -v $(pwd):/srv/jekyll:Z jekyll/jekyll jekyll serve --watch --future
  ```

  **NOTE**: The Z at the end of the volume (-v) will relabel its contents so it can be written from within the container, like running `chcon -Rt svirt_sandbox_file_t -l s0:c1,c2` yourself.  Be sure that you have changed your present working directory to the git cloned directory as shown above.

- On an OS without SELinux:

  ```console
  podman run -it --rm --name kubevirtio -p 4000:4000 -v $(pwd):/srv/jekyll jekyll/jekyll jekyll serve --watch --future
  ```

### Verify internal and external hyperlinks

  ```console
  podman run -it --rm --name kubevirtio -p 4000:4000 -v $(pwd):/srv/jekyll jekyll/jekyll /bin/bash -c "bundle install; rake";
  ```

### View the site

Visit `http://0.0.0.0:4000` in your local browser.
The KubeVirt.io website is a Jekyll site, hosted with GitHub Pages.

All pages are located under `/pages`. Each section of the site is broken out into their respective folders - `/blogs` for the various Blog pages, `/docs` for the Documentation and `/videos` for the videos that are shared.

All site images are located under `/assets/images`. Please do not edit these images.

Images that relate to blog entries are located under `/assets/images/BLOG_POST_TITLE`. The **BLOG_POST_TITLE** should match the name of the markdown file that you added under `/_posts`.
