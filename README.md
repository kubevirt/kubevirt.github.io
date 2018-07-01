example
=======

[![Build Status](https://travis-ci.org/kubevirt/kubevirt.github.io.svg?branch=master)](https://travis-ci.org/kubevirt/kubevirt.github.io)

# KubeVirt.io Website

## Creating a Blog Post

All Blog posts are located in the `/_posts` directory. Each file is a Markdown (`.md`) file.

In order to create a blog post for KubeVirt.io, you need to complete the following steps:

- create a markdown file with a `YYYY-MM-DD-TITLE` naming convention
- in the Front Matter (Jekyll configuration for a Blog post), you need to add the following:

```jekyll
---
layout: post
author: Your Name
description: Title of Blog Post
navbar_active: Blogs
pub-date: June 20
pub-year: 2018
category: news
comments: true
---
```

- `layout`: The layout is for the type of site layout that this uses. All Blog posts use the **posts** layout.
- `author`: Author is the name you would like to appear on the post. It is recommended to either use your GitHub username, Twitter handle, or another identifier that is known in the community.
- `description`: This is what will appear as the title of the Blog post.
- `navbar_active: Blogs`: This should not be changed, as it governs how the navigation appears.
- `pub-date`: This is the month and day that the Blog post was published. This should match the month and day in the file name.
- `pub-year`: This is the year that the Blog post was published. A cateogry of posts groups them by year.This should match the year in the file name.
- `category`: If desired, you can add a category to the post. If you do not wish it to be specifically categorized, please use **uncategorized**.
- `comments: true`: This enables the Disqus comments at the bottom of the post. If you do not wish a post to have commenting, do not include this line.

## Create a Page

All Pages are located in the `/pages` directory, and then broken down into the navigation section (i.e. `/blogs`, `/docs`, `/videos`, etc.). Each page should have the following Front Matter configuration:

```jekyll
---
layout: default
title: Introduction
permalink: /docs/
navbar_active: Docs
---
```

- `layout`: The layout is the type of site layout that the page uses. In this case, it is the default layout (includes header, body, and footer).
- `title`: This is the title of the page. It will appear at the top of the page, as well as in the browser navigation tab.
- `permalink`: This is the subsection that the page lives under. In this case, it is under `/docs/` and is the primary page of the Docs link. If you want this to be a page other than the primary, add the correct name afterwards (i.e. `/docs/authorization`).
- `navbar_active`: This selects which primary navigation item should be set as *active*. Use **Docs** for Documentation, **Blogs** for Blog Posts, and **Videos** for Videos. These are case-sensitive.

If you add a new page and want it to appear in the sidebar of that section (such as the sidebar under **Docs**), then you also need to update the `yaml` file associated with that group. These are located under `_data/`. For **Docs**, you would update `docs_toc.yml`, following the structure that currently exists within that file.

## Linking

When creating a link within KubeVirt.io, they all should include `{{ site.baseurl }}` before the location.

Example are `href="{{ site.baseurl }}/assets/images/image1.jpg"` to properly locate the file `image1.jpg`. For page linking, you would use `href="{{ site.baseurl }}/get_kubevirt"` to link to the Get KubeVirt information.

## Features

As part of KubeVirt.io, comments on Blog Posts and connections to Twitter are now enabled. Depending on your content settings, you will see Disqus conversation blocks at the end of each Blog Post, as well as a "Tweet" button, enabling you to post a Tweet a link to the Post, the Title and tag the @kubevirt account.

Under the Community page, depending on your content settings, you will be able to see a live feed of the @kubevirt account.

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
The KubeVirt.io website is a Jekyll site, hosted with GitHub Pages.

All pages are located under `/pages`. Each section of the site is broken out into their respective folders - `/blogs` for the various Blog pages, `/docs` for the Documentation and `/videos` for the videos that are shared.

All site images are located under `/assets/images`. Please do not edit these images.

Images that relate to blog entries are located under `/assets/images/BLOG_POST_TITLE`. The **BLOG_POST_TITLE** should match the name of the markdown file that you added under `/_posts`.
