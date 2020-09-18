# CWMS Database

This repository contains the information necessary to both create a CWMS database from scratching as well as upgrade existing database.

## Contributing

clone the repository with 

    git clone https://bitbucket.hecdev.net/scm/cwms/cwms_database.git

Use a token, created through the bitbucket account management interface, instead of your password. Certain operations will fail if your username/password combination is used.

Once you've decided on what you'll be working on create a branch (or checkout an existing branch if helping someone.)

    git checkout -b <branch name>

You one of the following prefixes for your branch

- feature
- bugfix
- hotfix

Other branch names are completely valid, but they won't automatically build without a pull request being created.

All contributions will be made through a Pull Request. If you have write access to the repistory simply push your branch with the following:

    git push origin <branch name>

And then go to the bitbucket site and create the PR. 

Please do this as early as possible in your development cycle. This will help prevent duplication of work and open up a consistent communication channel. It is expected that ones initial submission will not meet all of the requirements and guidance will be provided.

For you code to be accepted it must successfully install into oracle and be approved by one of the people at the bottom of this readme in the the Reviewers section.

In the future we will enforce coding style standards and test coverage. 

If you do not have write access you may be able to fork it in bitbucket and submit a PR from the fork. If that doesn't work contact one of the Reviewers for access.

## Reviewers

Mike Neilson
Mike Perryman
Prasad Vemulapati

