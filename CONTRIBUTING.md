# Contributing to Legal-Eagle

:+1::tada: First off, thanks for taking the time to contribute! :tada::+1:

Our [README](README.md) describes the project, its purpose, and caveats, and is necessary reading for contributors.

This project adheres to the Contributor Covenant [code of conduct](CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code.
Please report unacceptable behavior to [atom@github.com](mailto:atom@github.com).

Contributions to this project are made under the [MIT License](LICENSE.md).

## Help wanted

Browse [open issues](https://github.com/atom/legal-eagle/issues) to see current requests.

[Open an issue](https://github.com/atom/legal-eagle/issues/new) to tell us about a bug. You may also open a pull request to propose specific changes, but it's always OK to start with an issue.

## Testing

This project currently doesn't have automated tests. However, it is used by the [Atom](https://github.com/atom/atom) and [GitHub Desktop](https://github.com/desktop/desktop) projects, and changes may be manually tested against these:

1. Fork this repo
2. Clone your fork locally
3. Make your changes
4. Run `npm install`
5. Run `npm link` ([documentation](https://docs.npmjs.com/cli/link))
6. Setup [Atom](https://github.com/atom/atom/tree/master/docs#build-documentation) and [GitHub Desktop](https://github.com/desktop/desktop/blob/master/docs/contributing/setup.md) development directories
7. Run `npm link eagle-eagle` in your Atom and GitHub Deskop development directories
8. Run `script/build` in your Atom and GitHub Deskop development directories (these processes invoke legal-eagle and may fail if you introduced a crash or false negative license detection)

You can repeat steps 3, 4, and 8 without repeating the others.

## Resources

- [Contributing to Open Source on GitHub](https://guides.github.com/activities/contributing-to-open-source/)
- [Using Pull Requests](https://help.github.com/articles/about-pull-requests/)
- [GitHub Help](https://help.github.com)
