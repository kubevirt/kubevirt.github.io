example
=======

[![Build Status](https://travis-ci.org/kubevirt/kubevirt.github.io.svg?branch=master)](https://travis-ci.org/kubevirt/kubevirt.github.io)

All Pages Are stored in Directory: pages
All Blog post are stored in Directory:  _posts

Main page content is mostly in index.html (will change).
The whyKebvirt section in the Main page can be edited in pages/whykubevirt.md under summary
Images that are related to the site structure are folder: assets/images -> please do not touch unless images are related to the structure
Images that related to specific content are in folder assets/contenttype. Example: assets/blog_images

## Test your changes in a local container

### selinux labelling

```
# sudo chcon -Rt svirt_sandbox_file_t .
```

### Run a jekyll container

```
sudo docker run -d --name kubevirtio -p 4000:4000 -v $(pwd):/srv/jekyll jekyll/jekyll serve --watch
```

### View the site

Visit `http://0.0.0.0:4000` in your local browser.
