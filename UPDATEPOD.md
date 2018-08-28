for Zetapush only
edit Zetapush.podspec
# set the new version to 0.0.1
# set the new tag to 0.0.1

$ git add -A && git commit -m "Release 0.0.1."
$ git tag '0.0.1'
$ git push --tags

pod trunk push Zetapush.podspec
