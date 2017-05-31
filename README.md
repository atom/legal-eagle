# Legal Eagle [![Build Status](https://travis-ci.org/atom/legal-eagle.svg?branch=master)](https://travis-ci.org/atom/legal-eagle)

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
