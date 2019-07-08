# Contents Guidelines

This document describes a set of guidelines for generating contents for [KubeVirt.io](https://kubevirt.io), exceptions can be make if and when it makes sense, but please try to follow this guide as much as possible.

## General contents guidelines

Please use the following as general guidelines on any kind of contents generated for this site:

* Follow [Kramdown Quick Reference](https://kramdown.gettalong.org/quickref.html) for syntax reference
* Split the contents in sections using the different levels of headers that Markdown offers
  * Keep in mind that once rendered, the title you set in the Front Matter data will use *H1*, so start your sections from *H2*
* Closing section, the same way we can add a brief opening section describing what the contents is about, it's very important to add a closing section with thoughts, upcoming work on the topic discussed, encourage readers to test something and share their findings/thoughts, joining the community, ... keep in mind that this will probably be the last thing the reader will read
* [Code blocks](https://kramdown.gettalong.org/syntax.html#code-blocks), use them for:
  * code snippets
  * file contents
  * console commands
  * ...
  * Use the proper tag to let the renderer what type of contents your including in the block for syntax highlighting
* Consistency is important, makes it easier for the reader to follow along, for instance:
  * If you're writing about something running on OCP, use `oc` consistently, don't mix it up with `kubectl`
  * If you add your shell prompt to your console blocks, add it always or don't, but don't do half/half
* Use backticks (`) when mentioning commands on your text, like we do in this document
* Use *emphasis/italics* for non-English words such as technologies, projects, programming language keywords...
* Use bullet points, these are a great way to clearly express ideas through a series of short and concise messages
  * Express clear benefit. Think of bullets as mini-headlines
  * Keep your bullets symmetrical. 1-2 lines each
  * Avoid bullet clutter. Don’t write paragraphs in bullets
  * Remember bullets are not sentences. They’re just like headlines
* Use of images
  * Images are another great way to express information, for instance, instead of trying to describe your way around a UI, just add a snippet of the UI, readers will understand it easier and quicker
  * Avoid large images, if you have to try to resize them, otherwise the image will be wider than the writing when your contents is rendered
  * Linking or HTTP references
    * Linking externally can be problematic, some time after the publication of your contents, try linking to the repositories or directories, website's front page rather than to a page, etc.
    * For linking internally use [Jekyll's tags](https://jekyllrb.com/docs/liquid/tags/#links)
      * For blog posts
        ```markdown
        [Name of Link]({{ site.baseurl }}{% post_url 2010-07-21-name-of-post %})
        ```
      * For pages, collections, assets, etc
        ```markdown
        [Link to a document]({% link _collection/name-of-document.md %})
        [Link to a file]({% link /assets/files/doc.pdf %})
        ```

## Contents types

### Blog Posts

All Blog posts are located in the [_posts](/_posts/) directory, each entry is a Markdown file with extension *.md* or *.markdown*. For creating a blog post for [KubeVirt.io](https://kubevirt.io), you need to complete the following steps:

* Create a markdown file with the *YYYY-MM-DD-TITLE.markdown* naming convention
* For the [Front Matter](https://jekyllrb.com/docs/front-matter/), you need to add the following:

  ```yaml
  ---
  layout: post
  author: Your Name
  title: Title of Blog Post
  description: Excerpt of the Blog Post
  navbar_active: Blogs
  pub-date: June 20
  pub-year: 2019
  category: news
  comments: true
  ---
  ```

  * **layout**: Defines style settings for different types of contents. All blog posts use the *posts* layout
  * **author**: Sets the author's name, will publicly appear on the post. As a rule of thumb, use your GitHub username, Twitter handler or any other identifier known in the community
  * **title**: The title for your blog post
  * **description**: Short extract of the blog post
  * **navbar_active**: Defines settings for the navigation bar, type *Blogs* is the only choice available
  * **pub-date**: Month and day, together with *pub-year* form the date that will be shown in the blog post as the date it was published, must match the date on the file name
  * **pub-year**: Blog post publication year, must match the year in the file name
  * **category**: Array of categories for your blog post, some common ones are community, news and releases, as last resort, use uncategorized. If you'd like to add multiple categories, used *categories* instead of *category* and a [YAML list](https://en.wikipedia.org/wiki/YAML#Basic_components)
  * **comments**: This enables comments your blog post. Please consider setting this to *true* and allow discussion around the topic you're writing, otherwise skip the field or set it to false

* Blog post contents recommendation: 

  * Title is a very important piece of your blog post, a catchy title will likely have more readers, write a bad title and no matter how good the contents is, you'll likely get less readers
  * After the title, write a brief introduction of what you're going to be writing about, which will help the reader to get a grasp on the topic
  * Closing section, the same way we can add a brief introduction of what the blog post is about, it's very important to add a closing section with thoughts, upcoming work on the topic discussed, encourage readers to test something and share their findings, joining the community, ...

### Pages

*[Pages](https://jekyllrb.com/docs/pages/)* are located at the [pages](/pages/) directory, to create one follow these steps:

* Create the markdown file, *filename.md*, in [pages](/pages/) directory
* *Pages* also use [Front Matter](https://jekyllrb.com/docs/front-matter/), here's an example:

  ```yaml
  ---
  layout: default
  title: Introduction
  permalink: /docs/
  navbar_active: Docs
  ---
  ```

* The fields have the same function as for blog posts, but some values are different, as we're producing different contents.
  * **permalink** tells *Jekyll* what the output path for your page will be, it's useful for linking and web indexers
  * **navbar_active** will add your page to the navigation bar you specify as value, commonly used values are *Docs* or *Videos*
  * **layout**, just use *default* as value, it'll include all the necessary parts when your page is generated 

* As for the contents, follow the general guidelines above

### Labs

Labs are usually a set of directed excercises with the objective of teaching something by practising it, e.g. KubeVirt 101, which would introduce KubeVirt to new and potential users through a series of easy (101!) exercises. Labs are composed of a [Landing page](https://en.wikipedia.org/wiki/Landing_page) and the actual exercises.

#### Lab landing page

[Landing pages](https://en.wikipedia.org/wiki/Landing_page) are the book cover for your lab, for creating it, please follow these steps:

* Use the following Front Matter block includes data for the for your lab's [landing page](https://en.wikipedia.org/wiki/Landing_page), replacing the values by your own:

```yaml
---
layout: labs
title: KubeVirt 101 Lab
order: 1
permalink: labs/kubevirt101.html
navbar_active: Labs
---
```

* Modify **title** and **permalink**, and leave the rest as shown in the example
* For the contents, some recomendations:
  * Describe the lab objectives clearly.
  * Clearly state the requirements if any, e.g. laptop, cloud account, ...
  * Describe what anyone would learn when taking the lab.
  * Add references to documentation, projects, ...

#### Lab pages

These are the pages containing actual lab, exercises, documentations, etc... and each of them has to include a similar Front Matter block to the one that follows:

```yaml
---
layout: labs 
title: Installing KubeVirt
permalink: /labs/kubevirt101/lab01
lab: KubeVirt 101 Lab
order: 1
```

This time we've got a new field, *lab*, which matches the lab *title* from the Front Matter block on the landing page above, this is used to build the table of contents. Both *order* and *layout* should stay as they are in the example and just adjust the *title* and *permalink*.

Again use the concepts from the general guidelines section and apply the following suggestions when it makes sense:

* When asking to execute a command that'll produce output, add the output on the lab so the user knows what to expect.
* When working through labs that work on documented features, link to the official documentation either through out the lab or in a *reference* section in the landing page.
* Be mindful about using files from remote Git repositories or similar, especially if they're not under your control, they might be gone after a while.
