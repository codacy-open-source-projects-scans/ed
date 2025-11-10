# README EXTRA for ed repo

## Why this repo was created?

The GNU ED editor is still under active development; unfortunately, the official repository is not available.


https://cvs.savannah.gnu.org/viewvc/ed/ed/?hideattic=0


Shows only manual and dead files… Official site on Savannah


https://savannah.gnu.org/cvs/?group=ed


It provides the same CVS repository that is not actively maintained.


That’s why this repository was created to provide a backup, easy to access version in
a VCS (git). **Each release has tag.**


The code itself is not modified. There are 3 extra files: 

- README-EXTRA.md: This file.
- update-repo.sh: Script to update the repository.
- .github/workflows/run-daily.yml that runs the update-repo.sh script daily in the form of proper GitHub Action.

The releases are downloaded from the official site:
https://download.savannah.gnu.org/releases/ed/

## Personal note
Like many projects made by FSF, this project has very limited resources, and a single person is on it's mailing list.


https://savannah.gnu.org/projects/ed


Please consider donating to FSF to help them maintain their projects.
