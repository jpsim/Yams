## Tracking Changes

All changes should be made via pull requests on GitHub.

When issuing a pull request, please add a summary of your changes to the
`CHANGELOG.md` file.

We follow the same syntax as [CocoaPods' `CHANGELOG.md`](https://github.com/CocoaPods/CocoaPods/blob/master/CHANGELOG.md):

1. One Markdown unnumbered list item describing the change.
2. 2 trailing spaces on the last line describing the change.
3. A list of Markdown hyperlinks to the change's contributors. One entry
   per line. Usually just one.
4. A list of Markdown hyperlinks to the issues the change addresses. One entry
   per line. Usually just one.
5. All `CHANGELOG.md` content is hard-wrapped at 80 characters.

## Updating CI Jobs

CI jobs for the latest official Swift and Xcode releases should be kept
up to date based on the available Xcode versions that can be found
in the [actions/virtual-environments](https://github.com/actions/virtual-environments/blob/main/images/macos/macos-10.15-Readme.md#xcode)
repo.
