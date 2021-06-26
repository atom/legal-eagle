readInstalled = require 'read-installed'
{size, extend} = require 'underscore'
{basename, extname, join} = require 'path'
{existsSync, readdirSync, readFileSync} = require 'fs'

module.exports = (options, cb) ->
  {path, overrides, omitPermissive} = options
  readInstalled path, null, (err, packageData) ->
    return cb(err) if err?
    try
      licenseSummary = overrides ? {}
      findLicenses(licenseSummary, packageData, path)
      omitPermissiveLicenses(licenseSummary) if omitPermissive
      cb(null, licenseSummary)
    catch err
      cb(err)

findLicenses = (licenseSummary, packageData, path) ->
  # Unmet dependencies are left as strings
  return if typeof packageData is 'string'

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
  if license && license.type?
    license = license.type
  if Object.prototype.toString.call(license) == '[object Array]'
    license = license[0]
  result_dir = extractLicenseFromDirectory(path, license)
  if result_dir && result_dir['license']
    result_dir
  else if license?
    license = mungeLicenseName(license)
    result = {license, source: 'package.json'}
    if result_dir && result_dir['sourceText']
      result['sourceText'] = result_dir['sourceText']
    result
  else if readme and readme isnt 'ERROR: No README data found!'
    extractLicenseFromReadme(readme) ? {license: 'UNKNOWN'}
  else
    extractLicenseFromReadmeFile(path) ? {license: 'UNKNOWN'}

mungeLicenseName = (license) ->
  return unless license
  if license.match /[\s(]*BSD-.*/
    'BSD'
  else if license.match /[\s(]*Apache.*/
    'Apache'
  else if license.match /[\s(]*ISC.*/
    'ISC'
  else if license.match /[\s(]*MIT.*/
    'MIT'
  else if license is 'WTFPL'
    'WTF'
  else if license.match /[\s(]*unlicen[sc]e/i
    'Unlicense'
  else if license.match /[\s(]*CC-BY(-\d(\.\d)*)?/i
    'CC-BY'
  else if license.match /[\s(]*Public Domain/i
    'Public Domain'
  else if license.match /[\s(]*LGPL(-.+)*/
    'LGPL'
  else if license.match /[\s(]*[^L]GPL(-.+)*/
    'GPL'
  else
    license

extractLicenseFromReadme = (readme) ->
  return unless readme?

  license =
    if readme.includes('MIT')
      'MIT'
    else if readme.includes('BSD')
      'BSD'
    else if readme.includes('Apache License')
      'Apache'
    else if readme.includes('DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE')
      'WTF'
    else if readme.includes('Unlicense') or readme.includes('UNLICENSE')
      'Unlicense'
    else if readme.toLocaleLowerCase().includes('public domain')
      'Public Domain'

  if license?
    {license, source: 'README', sourceText: readme}

extractLicenseFromReadmeFile = (path) ->
  try
    readmeFiles = readdirSync(path).filter (child) ->
      name = basename(child, extname(child))
      name.toLowerCase() is 'readme'
  catch error
    return

  for readmeFilename in readmeFiles
    if license = extractLicenseFromReadme(readIfExists(join(path, readmeFilename)))
      return license
  return

extractLicenseFromDirectory = (path, expected) ->
  noticesText = ''
  for f in readdirSync(path)
    if f.match(/(licen[s|c]e|copying)/i) && !f.match(/\.(docs|json|html)$/i)
      potentialLicenseText = readIfExists(join(path, f))
      potentialLicenseFileName = f
      potentialLicense = licenseFromText(potentialLicenseText)
      if expected && potentialLicense && (expected.toLowerCase().indexOf(potentialLicense.toLowerCase()) != -1)
        licenseFileName = f
        licenseText = potentialLicenseText
        license = potentialLicense
    if f.match(/notice/i)
      noticesText = noticesText + readIfExists(join(path, f)) + '\n\n'

  licenseFileName ?= potentialLicenseFileName
  licenseText ?= potentialLicenseText
  if noticesText
    licenseText = noticesText + licenseText
  license ?= potentialLicense || expected
  license = mungeLicenseName(license)
  return unless licenseText?
  {license, source: licenseFileName, sourceText: licenseText}

licenseFromText = (licenseText) ->
  if licenseText.includes('Apache License')
    'Apache'
  else if isMITLicense(licenseText)
    'MIT'
  else if isBSDLicense(licenseText)
    'BSD'
  else if isUnlicense(licenseText)
    'Unlicense'
  else if licenseText.includes('The ISC License')
    'ISC'
  else if licenseText.includes('GNU LESSER GENERAL PUBLIC LICENSE')
    'LGPL'
  else if licenseText.includes('GNU GENERAL PUBLIC LICENSE')
    'GPL'
  else if licenseText.toLocaleLowerCase().includes('public domain')
    'Public Domain'

readIfExists = (path) ->
  readFileSync(path, 'utf8') if existsSync(path)

normalizeLicenseText = (licenseText) ->
  licenseText.replace(/\s+/gm, ' ').replace(/\s+$/m, '').replace(/\.$/, '').trim()

MITLicenseText = """
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
""".replace(/\s+/gm, ' ')

isMITLicense = (licenseText) ->
  if licenseText.includes('MIT License')
    true
  else
    startIndex = licenseText.indexOf('Permission is hereby granted')
    if startIndex > -1
      normalizedLicenseText = normalizeLicenseText(licenseText[startIndex..])
      normalizedLicenseText is MITLicenseText
    else
      false

BSD3LicenseText = """
  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  THIS IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE
""".replace(/\s+/gm, ' ')

isBSDLicense = (licenseText) ->
  if licenseText.includes('BSD License')
    true
  else
    startIndex = licenseText.indexOf('Redistribution and use')
    if startIndex > -1
      normalizedLicenseText = normalizeLicenseText(licenseText[startIndex..])
      normalizedLicenseText is BSD3LicenseText
    else
      false

UnlicenseText = """
  This is free and unencumbered software released into the public domain.

  Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

  In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

  For more information, please refer to <http://unlicense.org/>
""".replace(/\s+/gm, ' ')

isUnlicense = (licenseText) ->
  if licenseText.includes('Unlicense')
    true
  else
    startIndex = licenseText.indexOf('This is free and unencumbered software')
    if startIndex > -1
      normalizedLicenseText = normalizeLicenseText(licenseText[startIndex..])
      normalizedLicenseText is UnlicenseText
    else
      false

PermissiveLicenses = ['MIT', 'BSD', 'Apache', 'WTF', 'LGPL', 'LGPL-2.0', 'LGPL-3.0', 'ISC', 'Artistic-2.0', 'Unlicense', 'CC-BY', 'Public Domain']

omitPermissiveLicenses = (licenseSummary) ->
  for name, {license} of licenseSummary
    delete licenseSummary[name] if license in PermissiveLicenses
