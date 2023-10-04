##### Atom and all repositories under Atom will be archived on December 15, 2022. Learn more in our [official announcement](https://github.blog/2022-06-08-sunsetting-atom/)
 # Legal Eagle [![CI](https://github.com/atom/legal-eagle/actions/workflows/ci.yml/badge.svg)](https://github.com/atom/legal-eagle/actions/workflows/ci.yml)

A library for listing the licenses of an npm module's dependencies.

## Basic Usage

Provide the path to the module in question and a callback. Your callback will
be passed a hash with the name@version of each dependency as a key and its
`license`, `source`, and `sourceText`.

```coffee
legalEagle = require 'legal-eagle'

legalEagle {path: process.cwd()}, (err, summary) ->
  return console.error(err) if err?
  console.log(summary)
```

## Optional Parameters

### Omit Permissive Licenses

Pass `omitPermissive: true` in the params hash to only list unknown or
non-permissive licenses in the summary.

### License Overrides

If you know the license of a given dependency but this library can't
automatically determine it, pass an `overrides` hash with its name@version as
the key and the `license`, `source` and `sourceText` you want to use in the
summary.

## License

[MIT](LICENSE.md)

## Dependency note

`coffee-cache` and `rimraf` aren't actually used in the code, they're just nice
developer utils.
