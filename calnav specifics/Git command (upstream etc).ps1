git fetch upstream
git checkout main ## the upstream branch is called 
git merge upstream/main ## merge the upstream changes into your local main branch
git checkout CAL-Peter ### switch to your feature branch
git merge main ### merge the updated main branch into your feature branch
## after this step a merge commit will be created if there are any conflicts. Resolve them if necessary.
## the commit message is shown in a vim editor keys to use in vim:
## :wq to save and exit
## to add a line : press 'i' to enter insert mode, type your line, then press 'Esc' to exit insert mode.
## to delete a line: press 'dd' to delete the current line.
## finally, after resolving any conflicts and saving the merge commit message, you can push your changes to your forked repository:
git push origin CAL-Peter
