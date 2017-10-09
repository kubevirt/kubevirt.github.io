# Contribution workflow

What follows is an outline of the end-to-end contribution workflow for getting
changes made in the KubeVirt project. In general terms, it applies to all the
GIT repositories associated with the project, however, some steps may be
omitted with certain repositories for expediency. In addition to these
guidelines, also read any CONTRIBUTING.md file that is present in the GIT
repository being modified. This will contain any important instructions that
are specific to the repository.

## Process summary

The quick summary of contribution process is as follows

* Identify an existing issue or file a new issue for the work
* Set assignee of the issue to indicate it is being worked on
* If appropriate, write a design document for the docs/ directory
* Write the code changes, signing off the commit message
* Submit a pull request with the design doc and / or code changes
* Wait for automated testing results and/or reviewer comments
* If needed, address pull request feedback and update the pull request
* Pull requests is approved for merge and issue is closed

## Issue tracking

Each of the project's [GIT repositories](https://github.com/kubevirt) has a
corresponding issue tracker associated with it. The issues serve to record work
that needs to be done on the code, and identify who (if anybody) is known to be
working on it. An issue may represent one of a number of different types of
work item, including a bug report, a identified feature gap, a feature wishlist
item. When dealing with features, the issue is not the place to write up a full
design for the implementation. Instead it just serves as a place to consider
the acceptability of the feature request at a high level.

If a person is actively working on an issue, it is expected that they set
themselves as the assignee for it, to prevent others accidentally duplicating
effort. If a contributor does not have permission to set themselves as assignee,
they can add a comment to the issue asking to be made the assignee. Similarly
if an assignee has to stop their work for whatever reason, it is polite to
either unassign themselves from the issue, or put a comment on it mentioning
the pause in activity. This gives a chance for other interested contributors to
pick up the work.

When fixing an issue, the commit message of the patch that provides the fix
must mention the issue tracker number. The pull request may also mention the
issue tracker number, but this is not mandatory. The issue tracker number must
be listed in the [format defined by
github](https://help.github.com/articles/closing-issues-via-commit-messages/,
in order to ensure that the issue is automatically closed when the code is
merged.

If no issue currently exists for the work being planned / undertaken, it is
recommended to file a new issue. This is primarily to alert other contributors
to the fact that the work is being done.


## Design documents

In some cases, particularly with new features, it may be desirable to write up
a semi-formal design for the work to be done. By convention design documents are
to be submitted as patches to the docs/ directory in the GIT repository that
will later contain the implementation. Documents should be written in
[github markdown format](https://guides.github.com/features/mastering-markdown/)
unless there is a compelling reason to use an alternate format.

The design documents will serve many purposes, including

* Highlight the problems / requirements to be addressed by the work
* Outline and evaluate differing approaches to the implementation
* Provide context for the people reviewing later code contributions
  to help them evaluate suitability of the implementation
* Provide context for the people writing formal documentation for
  the feature.

Design documents are typically only used in GIT repositories that are focused
on software deliverables, such as the primary
"[kubevirt](https://github.com/kubevirt/kubevirt)" repository and the
"[project-infra](https://github.com/kubevirt/project-infra)" repository.
Repositories serving other purposes such as the
"[kubvirt.github.io](https://github.com/kubevirt/kubevirt.github.io)" website
content or the "community" content, do not make use of design documentation.

There is no mandatory requirement to get a design document approved and merged
before starting on the code development. Contributors can choose to submit a
design doc upfront and get it reviewed and merged before starting coding. This
is particularly recommended for complicated or potentially controversial code
changes. Alternatively it is acceptable to submit the design doc as the first
commit in a series of commits that implement the desired feature. The former
will reduce the risk of code development taking an approach that is later
rejected, while the later may allow faster development. Even once a design
document is reviewed and merged, it is not mandatory to blindly follow it. If
changes come to light during development that invalidate some of the design
decisions, contributors should simply include an update to the design doc in one
of the commits, to reflect the changed reality.


## Developer certification

All patches submitted for merge to any of the project's GIT repositories are
required to be signed off in accordance with the following:

> Developer Certificate of Origin
> Version 1.1
>
> Copyright (C) 2004, 2006 The Linux Foundation and its contributors.
> 1 Letterman Drive
> Suite D4700
> San Francisco, CA, 94129
>
> Everyone is permitted to copy and distribute verbatim copies of this
> license document, but changing it is not allowed.
>
> Developer's Certificate of Origin 1.1
>
> By making a contribution to this project, I certify that:
>
> (a) The contribution was created in whole or in part by me and I
>     have the right to submit it under the open source license
>     indicated in the file; or
>
> (b) The contribution is based upon previous work that, to the best
>    of my knowledge, is covered under an appropriate open source
>    license and I have the right under that license to submit that
>    work with modifications, whether created in whole or in part
>    by me, under the same open source license (unless I am
>    permitted to submit under a different license), as indicated
>    in the file; or
>
>(c) The contribution was provided directly to me by some other
>    person who certified (a), (b) or (c) and I have not modified
>    it.
>
>(d) I understand and agree that this project and the contribution
>    are public and that a record of the contribution (including all
>    personal information I submit with it, including my sign-off) is
>    maintained indefinitely and may be redistributed consistent with
>    this project or the open source license(s) involved.

Assuming the author accepts the statement above, they can certify compliance
by adding the following line to each GIT commit message:

    Signed-off-by: Your Name <your@email-address.com>

This can be automatically added in the correct format by passing the `-s`
argument when running `git commit`.

This simple signoff process removes the need for the project to have any more
formal contributor license agreement.

## Code submission

All changes to the project must be submitted as pull requests against the
relevant GIT repository for code review prior to approval for merge

Depending on the repository, a number of automated tests will be performed on
the submission, including a check that every commit has been signed off in
accordance with the developer certificate of origin. Results of these automated
tests will be displayed on the pull request summary page. If any failures are
identified, the author is generally expected to resolve them and submit an
updated pull request, unless the failure is caused by a flaw in the automated
test system.

Anyone with a github account is able to make comments and requests changes on
pull requests, however, only members of the
*[maintainers](https://github.com/orgs/kubevirt/teams/maintainers/members)*
team are able to merge the code. Unless the author is very lucky, it is usual
to receive feedback that will require one or more rounds of code updates. When
submitting updated commits to review, always reuse the existing pull request
by pushing to the same branch that was originally used. It is rarely
appropriate to open a new pull request, after addressing review feedback, as
that throws away record of the previous comments.
