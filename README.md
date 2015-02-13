## Deprecation Warning

This repository has been deprecated in favor of individual cookbook repositories at the [top level Biola github org.](https://github.com/biola) 

### Git submodules

**NOTE:** This repository of cookbooks makes heavy use of git
submodules, and their upstream URLs may change unexpectedly (e.g., when
they are forked). It is advised to perform a `git submodule sync` after
pulling changes from this repository to ensure your local copy's
.git/modules/... configurations are up to date. This should make a `git
status` accurately reflect the state of the repository.

When cloning this repository for the first time, follow normal git procedures to pull in the submodule contents as well (e.g., `git clone https://github.com/biola/chef-cookbooks.git && cd chef-cookbooks && git submodule init && git submodule update`)
