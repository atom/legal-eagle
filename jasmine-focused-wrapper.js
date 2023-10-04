/**
 * `node_modules/.bin/jasmine-focused` is a `#!/bin/sh` file,
 * which node can't parse correctly anymore.
 *
 * So there needs to be a wrapper around the `node_modules/.bin/jasmine-focused`
 * file which node *can* parse
 */

const { exec } = require('child_process')
exec('sh node_modules/.bin/jasmine-focused --coffee --captureExceptions spec', (error, stdout, stderr) => {
   console.log(stdout)
   console.error(stderr)
   if (error !== null) {
      throw error
   }
})
