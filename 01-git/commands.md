# Git Commands

Every Git command used during the Git module and while building this repository, grouped by task. Where a command has a newer recommended form, both are shown.

## 1. Install and set up

```bash
sudo apt update
sudo apt install git
git --version

git config --global user.name "Your Name"
git config --global user.email "youremail@domain.com"
git config --list                     # check the settings
```

## 2. Get a repository

```bash
git clone <repo-url>                  # copy a GitHub repo to your machine
git remote -v                         # show the linked remote (origin)
```

## 3. Branches

```bash
git branch                            # list branches (* marks the current one)
git branch <branch>                   # create a branch (does not switch to it)

git switch <branch>                   # switch to a branch
git checkout <branch>                 # older form of the same

git switch -c <branch>                # create and switch in one step
git checkout -b <branch>              # older form of the same
```

## 4. Stage and commit

```bash
git status                            # see changed, staged and untracked files

git add <file>                        # stage one file
git add <folder>                      # stage a folder
git add .                             # stage everything in the current folder

git restore --staged <file>           # unstage a file (keep the edits)
git restore <file>                    # discard edits to a file

git commit -m "commit message"        # commit staged changes
git commit -a -m "commit message"     # stage and commit files Git already tracks
                                      # (new, untracked files still need git add)
```

## 5. Push, fetch and pull

```bash
git push -u origin <branch>           # first push of a branch: sets the upstream
git push origin <branch>              # later pushes

git fetch origin                      # download remote changes without merging
git pull origin <branch>              # fetch and merge into the current branch
```

When Git asks for a password over HTTPS, enter a **personal access token**: GitHub stopped accepting account passwords in August 2021. An SSH key or `gh auth login` avoids the prompt.

## 6. Pull requests and merge conflicts

Pull requests are created on GitHub after pushing a branch.

```bash
# Conflict practice: change the same line of one file on two branches
git switch main
git switch -c c1
# edit s1.txt
git add s1.txt
git commit -m "modified s1.txt"
git push -u origin c1

git switch main
# edit the same line of s1.txt
git add .
git commit -m "modified s1.txt in main"
git push origin main

# Raise a PR from c1 to main on GitHub: it reports a conflict.
# Resolve it in the GitHub editor, or locally:
git switch c1
git merge main                        # Git marks the conflicting lines
# edit the file, keep the right lines, remove the <<<<<<< ======= >>>>>>> markers
git add s1.txt
git commit -m "resolve conflict in s1.txt"
git push origin c1                    # the PR can now be merged
```

## 7. Remove and move files

```bash
git rm <file>                         # delete from the repo and from disk
git rm --cached <file>                # stop tracking, keep the file on disk
git rm -f <file>                      # force-remove a file that has staged changes
git mv <old> <new>                    # rename or move a file and keep its history
```

## 8. Stash (set work aside)

```bash
git stash                             # save uncommitted changes and clean the working tree
git stash list                        # list saved stashes
git stash show                        # summary of the latest stash
git stash show stash@{0}              # summary of a specific stash
git stash apply stash@{0}             # bring changes back, keep the stash
git stash pop                         # bring changes back and remove the stash
```

## 9. Reset (undo)

```bash
git reset --hard                      # throw away ALL uncommitted changes (cannot be undone)
git restore --staged <file>           # safer: unstage just one file
```

## 10. Rebase

```bash
git switch c1
git rebase c2                         # replay c1's commits on top of c2

git rebase c2 c1                      # same thing in one command:
                                      # first = base branch, second = branch that moves
```

## 11. History

```bash
git log                               # full commit history
git log --oneline --graph --all       # compact view with branches
```
