readInstalled = require 'read-installed'
{size, extend} = require 'underscore'
{join} = require 'path'
{existsSync, readFileSync} = require 'fs'

module.exports = (options, cb) ->
  {path, overrides, omitPermissive} = options
  readInstalled path, null, console.log, (err, packageData) ->
    return cb(err) if err?
    try
      licenseSummary = overrides ? {}
      findLicenses(licenseSummary, packageData, path)
      omitPermissiveLicenses(licenseSummary) if omitPermissive
      cb(null, licenseSummary)
    catch err
      cb(err)

findLicenses = (licenseSummary, packageData, path) ->
  {name, version, dependencies, engines} = packageData
  id = "#{name}@#{version}"

  return unless existsSync(path)

  unless licenseSummary[id]?
    entry = {repository: extractRepository(packageData)}
    extend(entry, extractLicense(packageData, path))
    licenseSummary[id] = entry

    if size(dependencies) > 0
      for name, data of dependencies
        dependencyPath = join(path, 'node_modules', name)
        findLicenses(licenseSummary, data, dependencyPath)

extractRepository = ({repository}) ->
  if typeof repository is 'object'
    repository = repository.url.replace('git://github.com', 'https://github.com').replace('.git', '')
  repository

extractLicense = ({license, licenses, readme}, path) ->
  license ?= licenses[0] if licenses?.length > 0
  if license?
    unless typeof license is 'string'
      license = license.type ? 'UNKNOWN'
    license = 'BSD' if license.match /^BSD-.*/
    license = 'MIT' if license is 'MIT/X11'
    license = 'Apache' if license.match /^Apache.*/
    license = 'WTF' if license is 'WTFPL'
    {license, source: 'package.json'}
  else
    extractLicenseFromReadme(readme) ? extractLicenseFromDirectory(path) ? {license: 'UNKNOWN'}

extractLicenseFromReadme = (readme) ->
  return unless readme?

  license =
    if readme.indexOf('MIT') > -1
      'MIT'
    else if readme.indexOf('BSD') > -1
      'BSD'
    else if readme.indexOf('Apache License') > -1
      'Apache'
    else if readme.indexOf('DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE') > -1
      'WTF'

  if license?
    {license, source: 'README', sourceText: readme}

extractLicenseFromDirectory = (path) ->
  licenseFileName = 'LICENSE'
  licenseText = readIfExists(join(path, licenseFileName))

  unless licenseText?
    licenseFileName = 'LICENSE.md'
    licenseText = readIfExists(join(path, licenseFileName))

  unless licenseText?
    licenseFileName = 'LICENSE.txt'
    licenseText = readIfExists(join(path, licenseFileName))

  unless licenseText?
    licenseFileName = 'LICENCE'
    licenseText = readIfExists(join(path, licenseFileName))

  unless licenseText?
    licenseFileName = 'MIT-LICENSE.txt'
    if licenseText = readIfExists(join(path, licenseFileName))
      license = 'MIT'

  return unless licenseText?

  license ?=
    if licenseText.indexOf('Apache License') > -1
      'Apache'
    else if isMITLicense(licenseText)
      'MIT'
    else if isBSDLicense(licenseText)
      'BSD'
    else if licenseText.indexOf('The ISC License') > -1
      'ISC'

  if license?
    {license, source: licenseFileName, sourceText: licenseText}

readIfExists = (path) ->
  readFileSync(path, 'utf8') if existsSync(path)

MITLicenseText = """
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
""".replace(/\s+/gm, ' ')

isMITLicense = (licenseText) ->
  if licenseText.indexOf('MIT License') > -1
    true
  else
    startIndex = licenseText.indexOf('Permission is hereby granted')
    if startIndex > -1
      normalizedLicenseText = licenseText[startIndex..].replace(/\s+/gm, ' ').replace(/\s+$/m, '')
      normalizedLicenseText is MITLicenseText
    else
      false

BSD3LicenseText = """
  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  THIS IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
""".replace(/\s+/gm, ' ')

isBSDLicense = (licenseText) ->
  if licenseText.indexOf('BSD License') > -1
    true
  else
    startIndex = licenseText.indexOf('Redistribution and use')
    if startIndex > -1
      normalizedLicenseText = licenseText[startIndex..].replace(/\s+/gm, ' ').replace(/\s+$/m, '')
      normalizedLicenseText is BSD3LicenseText
    else
      false

PermissiveLicenses = ['MIT', 'BSD', 'Apache', 'WTF', 'LGPL', 'ISC', 'Artistic-2.0']

omitPermissiveLicenses = (licenseSummary) ->
  for name, {license} of licenseSummary
    delete licenseSummary[name] if license in PermissiveLicenses
