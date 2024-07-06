# Unofficial Snap Packaging for [Project]

This is the unofficial snap packaging for [Project], [Snaps are universal Linux packages](https://snapcraft.io).

Refer [snap/README.md](snap/README.md) for user-oriented information.

<!--
<https://gitlab.com/_namespace_/_project_>  
[![The GitLab CI pipeline status badge of the project's `main` branch](https://gitlab.com/_namespace_/_project_/badges/main/pipeline.svg?ignore_skipped=true "Click here to check out the comprehensive status of the GitLab CI pipelines")](https://gitlab.com/_namespace_/_project_/-/pipelines) [![GitHub Actions workflow status badge](https://github.com/_namespace_/_project_/actions/workflows/check-potential-problems.yml/badge.svg "GitHub Actions workflow status")](https://github.com/_namespace_/_project_/actions/workflows/check-potential-problems.yml) [![pre-commit enabled badge](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white "This project uses pre-commit to check potential problems")](https://pre-commit.com/) [![REUSE Specification compliance badge](https://api.reuse.software/badge/gitlab.com/_namespace_/_project_ "This project complies to the REUSE specification to decrease software licensing costs")](https://api.reuse.software/info/gitlab.com/_namespace_/_project_)
-->

## Remaining Tasks

Snapcrafters ([join us](https://forum.snapcraft.io/t/join-snapcrafters/1325)) are working to land snap install documentation and the [snapcraft.yaml](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/blob/master/snap/snapcraft.yaml) upstream so [Project] can authoritatively publish future releases.

* [x] Create _snap_name_-snap (or any valid name you prefer) repository via the [Use this template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/generate) button above

      It is recommended to *avoid forking the template repository* unless you're working on the template itself because you can only fork a repository once
* [ ] Update the description of the repository
* [ ] Update logos and references to `[Project]`, `my-awesome-app`, `_namespace_`, `_project_`, and other placeholder names in `README.md`, `snap/README.md`, and `snap/snapcraft.yaml`
* [ ] Add upstream contact information to this `README.md`
* [ ] Create a snap that runs in `devmode`, [or in `classic` confinement if that's not possible](https://forum.snapcraft.io/t/subtle-differences-between-devmode-and-classic-confinement-snaps/7267)
    + [ ] If the snap must be packaged under `classic` confinement, file a [classic confinement request](https://forum.snapcraft.io/t/process-for-reviewing-classic-confinement-snaps/1460) topic in the Snapcraft Forum, under the `store` topic category - [template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/wiki/Classic-Confinement-Request-Template) - [link]()
* [ ] Add a screenshot to `snap/README.md`
* [ ] Register the snap in the Snap Store, **using the preferred upstream name**(i.e. without custom postfix).  If the preferred upstream name is not available or reserved, [file a request to take over the preferred upstream name](https://dashboard.snapcraft.io/register-snap) and temporary use a name with personal postfix instead.
* [ ] Setup [build.snapcraft.io](https://build.snapcraft.io) and publish the `devmode` snap in the Snap Store edge channel
* [ ] Add the provided Snapcraft build badge to `snap/README.md`
* [ ] Update snap's metadata, icons and screenshots on the [dashboard](https://dashboard.snapcraft.io)
* [ ] Add install instructions to `snap/README.md`
* [ ] File an Intent-To-Package issue/bug to the upstream's contact or issue/bug tracker to consolidate and let the upstream acknowledge the effort - [template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/wiki/Intent-To-Package-Template) - [link]()
* [ ] Convert the snap to `strict` confinement, or `classic` confinement if it qualifies
* [ ] Publish the confined snap in the Snap Store beta channel
* [ ] Update the install instructions in `snap/README.md`
* [ ] Post a call for testing on the [Snapcraft Forum](https://forum.snapcraft.io) - [template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/wiki/Call-for-Testing-Template) - [link]()
* [ ] Publish the snap in the Snap Store stable channel
* [ ] Update the install instructions in `snap/README.md`
* [ ] Post an announcement in the [Snapcraft Forum](https://forum.snapcraft.io) - [template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/wiki/Release-Announcement-Template) - [link]()
* [ ] Submit a pull request or patch upstream that adds the `snapcraft.yaml` and any required assets/launchers - [example](https://github.com/htacg/tidy-html5/pull/749) - [link]()
* [ ] Submit a pull request or patch upstream that adds snap install documentation - [example](https://github.com/htacg/html-tidy.org/pull/11) - [link]()

If the upstream accepts the PRs **AND** willing to maintain the package on the Snap Store:
* [ ] Request upstream create a Snap Store developer account
* [ ] Create a topic [under the `store` category in the Snapcrafters Forum](https://forum.snapcraft.io/c/store) to request the snap be transferred to upstream - [template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/wiki/Ownership-Transfer-Template#transfer-to-upstream) - [link]()

If the upstream rejects the offer:

* [ ] Ask a [Snapcrafters admin](https://github.com/orgs/snapcrafters/people?query=%20role%3Aowner) to fork your/upstream's repo into github.com/snapcrafters, transfer the snap name from you to snapcrafters, and configure the repo for automatic publishing into edge on commit - [template](https://github.com/Lin-Buo-Ren/snapcrafters-template-plus/wiki/Ownership-Transfer-Template#transfer-to-the-snapcrafters-organization) - [link]()

Finally:

* [ ] Ask the Snap Advocacy team to celebrate the snap - [explanation](https://forum.snapcraft.io/t/what-is-ask-the-snap-advocacy-team-to-celebrate-the-snap/8808/7) -  [link]()

If you have any questions, [post in the Snapcraft forum](https://forum.snapcraft.io).

<!--
Refer the following page for setting a Gravatar:

    Gravatar - Globally Recognized Avatars
    https://en.gravatar.com/

Refer the following page for how to generate Gravatar image URL:

    Developer Resources - Gravatar - Globally Recognized Avatars
    https://en.gravatar.com/site/implement/

You may generate the unique hash by using the following command in terminal:

    printf username@example.com | tr '[:upper:]' '[:lower:]' | md5sum

-->

<!--
## Contacts

| Packager | Upstream |
| :-: | :-: |
| [![Packager's avatar](http://gravatar.com/avatar/66a5b84972e73e895d5d68d48b1e1e22/?s=128)<br>Packager's name](mailto:packager.contact) | [![Upstream's avatar](GitHub-Mark.png)<br>Upstream's contact name](mailto:upstream.contact) |
-->

<!--
## References

The following resources are referenced during the development of this project:

To be addressed.
-->

## Licensing

Unless otherwise noted(individual file's header/[REUSE DEP5](.reuse/dep5)), this product is licensed under [the MIT license](https://opensource.org/license/mit), or any of its recent versions you would prefer.

This work complies to [the REUSE Specification](https://reuse.software/spec/), refer the [REUSE - Make licensing easy for everyone](https://reuse.software/) website for info regarding the licensing of this product.
