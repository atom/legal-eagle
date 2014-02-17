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

  return if engines?.atom?

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

  return unless licenseText?

  license =
    if licenseText.indexOf('Apache License') > -1
      'Apache'
    else if licenseText.indexOf('MIT License') > -1
      'MIT'

  if license?
    {license, source: licenseFileName, sourceText: licenseText}

readIfExists = (path) ->
  readFileSync(path, 'utf8') if existsSync(path)

PermissiveLicenses = ['MIT', 'BSD', 'Apache', 'WTF']

omitPermissiveLicenses = (licenseSummary) ->
  for name, {license} of licenseSummary
    delete licenseSummary[name] if license in PermissiveLicenses
