import {existsSync, readdirSync, readFileSync} from 'fs';
import {basename, extname, join} from 'path';
import {size, extend} from 'underscore';
import {BSD3LicenseText, MITLicenseText, UnlicenseText} from './license-texts';

const PermissiveLicenses = [
  'MIT',
  'BSD',
  'Apache',
  'WTF',
  'LGPL',
  'LGPL-2.0',
  'LGPL-3.0',
  'ISC',
  'Artistic-2.0',
  'Unlicense',
  'CC-BY',
  'Public Domain',
];

function extractRepository({repository}) {
  if (typeof repository !== 'object') {
    return repository;
  }

  return repository.url
    .replace('git://github.com', 'https://github.com')
    .replace('.git', '');
}

function extractLicense({license: licenseToExtract, licenses, readme}, path) {
  let license = licenseToExtract || licenses && licenses.length > 0 && licenses[0];

  const result = extractLicenseFromDirectory(path);
  if (result) {
    return result;
  }

  if (license != null) {
    if (typeof license !== 'string') {
      license = license.type != null ? license.type : 'UNKNOWN';
    }
    if (license.match(/[\s(]*BSD-.*/)) { license = 'BSD'; }
    if (license.match(/[\s(]*Apache.*/)) { license = 'Apache'; }
    if (license.match(/[\s(]*ISC.*/)) { license = 'ISC'; }
    if (license.match(/[\s(]*MIT.*/)) { license = 'MIT'; }
    if (license === 'WTFPL') { license = 'WTF'; }
    if (license.match(/[\s(]*unlicen[sc]e/i)) { license = 'Unlicense'; }
    if (license.match(/[\s(]*CC-BY(-\d(\.\d)*)?/i)) { license = 'CC-BY'; }
    if (license.match(/[\s(]*Public Domain/i)) { license = 'Public Domain'; }
    if (license.match(/[\s(]*LGPL(-.+)*/)) { license = 'LGPL'; }
    if (license.match(/[\s(]*[^L]GPL(-.+)*/)) { license = 'GPL'; }

    return {
      license,
      source: 'package.json',
    };
  } else if (readme && (readme !== 'ERROR: No README data found!')) {
    return extractLicenseFromReadme(readme) || {license: 'UNKNOWN'};
  } else {
    return extractLicenseFromReadmeFile(path) || {license: 'UNKNOWN'};
  }
}

function extractLicenseFromReadme(readme) {
  if (readme == null) {
    return;
  }

  let license;

  if (readme.indexOf('MIT') > -1) {
    license = 'MIT';
  } else if (readme.indexOf('BSD') > -1) {
    license = 'BSD';
  } else if (readme.indexOf('Apache License') > -1) {
    license = 'Apache';
  } else if (readme.indexOf('DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE') > -1) {
    license = 'WTF';
  } else if ((readme.indexOf('Unlicense') > -1) || (readme.indexOf('UNLICENSE') > -1)) {
    license = 'Unlicense';
  } else if (readme.toLocaleLowerCase().indexOf('public domain') > -1) {
    license = 'Public Domain';
  }

  if (license != null) {
    return {
      license,
      source: 'README',
      sourceText: readme,
    };
  }
}

function extractLicenseFromReadmeFile(path) {
  let readmeFiles;
  try {
    readmeFiles = readdirSync(path).filter(child => {
      const name = basename(child, extname(child));
      return name.toLowerCase() === 'readme';
    });
  } catch (error) {
    return;
  }

  for (const readmeFilename of readmeFiles) {
    const license = extractLicenseFromReadme(readIfExists(join(path, readmeFilename)));

    if (license) {
      return license;
    }
  }
}

function extractLicenseFromDirectory(path) {
  let license;
  let licenseFileName = 'LICENSE';
  let licenseText = readIfExists(join(path, licenseFileName));

  if (licenseText == null) {
    licenseFileName = 'LICENSE.md';
    licenseText = readIfExists(join(path, licenseFileName));
  }

  if (licenseText == null) {
    licenseFileName = 'LICENSE.txt';
    licenseText = readIfExists(join(path, licenseFileName));
  }

  if (licenseText == null) {
    licenseFileName = 'LICENCE';
    licenseText = readIfExists(join(path, licenseFileName));
  }

  if (licenseText == null) {
    licenseFileName = 'COPYING';
    licenseText = readIfExists(join(path, licenseFileName));
  }

  if (licenseText == null) {
    licenseFileName = 'COPYING.md';
    licenseText = readIfExists(join(path, licenseFileName));
  }

  if (licenseText == null) {
    licenseFileName = 'MIT-LICENSE.txt';
    licenseText = readIfExists(join(path, licenseFileName));

    if (licenseText) {
      license = 'MIT';
    }
  }

  if (licenseText == null) {
    const unlicenseFileNames = [
      'UNLICENSE',
      'UNLICENSE.md',
      'UNLICENSE.txt',
      'UNLICENCE',
      'UNLICENCE.md',
      'UNLICENCE.txt',
    ];

    for (licenseFileName of unlicenseFileNames) {
      licenseText = readIfExists(join(path, licenseFileName));

      if (licenseText) {
        license = 'Unlicense';
        break;
      }
    }
  }

  if (licenseText == null) {
    return;
  }

  if (license == null) {
    if (licenseText.indexOf('Apache License') > -1) {
      license = 'Apache';
    } else if (isMITLicense(licenseText)) {
      license = 'MIT';
    } else if (isBSDLicense(licenseText)) {
      license = 'BSD';
    } else if (isUnlicense(licenseText)) {
      license = 'Unlicense';
    } else if (licenseText.indexOf('The ISC License') > -1) {
      license = 'ISC';
    } else if (licenseText.indexOf('GNU LESSER GENERAL PUBLIC LICENSE') > -1) {
      license = 'LGPL';
    } else if (licenseText.indexOf('GNU GENERAL PUBLIC LICENSE') > -1) {
      license = 'GPL';
    } else if (licenseText.toLocaleLowerCase().indexOf('public domain') > -1) {
      license = 'Public Domain';
    }
  }

  if (license != null) {
    return {
      license,
      source: licenseFileName,
      sourceText: licenseText,
    };
  }
}

function readIfExists(path) {
  if (existsSync(path)) {
    return readFileSync(path, 'utf8');
  }
}

function normalizeLicenseText(licenseText) {
  return licenseText.replace(/\s+/gm, ' ')
    .replace(/\s+$/m, '')
    .replace(/\.$/, '')
    .trim();
}

function isMITLicense(licenseText) {
  if (licenseText.indexOf('MIT License') > -1) {
    return true;
  } else {
    const startIndex = licenseText.indexOf('Permission is hereby granted');
    if (startIndex > -1) {
      const normalizedLicenseText = normalizeLicenseText(licenseText.slice(startIndex));
      return normalizedLicenseText === MITLicenseText;
    } else {
      return false;
    }
  }
}

function isBSDLicense(licenseText) {
  if (licenseText.indexOf('BSD License') > -1) {
    return true;
  } else {
    const startIndex = licenseText.indexOf('Redistribution and use');
    if (startIndex > -1) {
      const normalizedLicenseText = normalizeLicenseText(licenseText.slice(startIndex));
      return normalizedLicenseText === BSD3LicenseText;
    } else {
      return false;
    }
  }
}

function isUnlicense(licenseText) {
  if (licenseText.indexOf('Unlicense') > -1) {
    return true;
  } else {
    const startIndex = licenseText.indexOf('This is free and unencumbered software');
    if (startIndex > -1) {
      const normalizedLicenseText = normalizeLicenseText(licenseText.slice(startIndex));
      return normalizedLicenseText === UnlicenseText;
    } else {
      return false;
    }
  }
}

export function findLicenses(licenseSummary, packageData, path) {
  // Unmet dependencies are left as strings
  if (typeof packageData === 'string') {
    return;
  }

  const {name, version, dependencies} = packageData;
  const id = `${name}@${version}`;

  if (!existsSync(path)) {
    return;
  }

  if (licenseSummary[id] == null) {
    const entry = {repository: extractRepository(packageData)};
    extend(entry, extractLicense(packageData, path));
    licenseSummary[id] = entry;

    if (size(dependencies) > 0) {
      return Object.keys(dependencies).map(dependencyName => {
        const data = dependencies[dependencyName];
        const dependencyPath = join(path, 'node_modules', dependencyName);

        return findLicenses(licenseSummary, data, dependencyPath);
      });
    }
  }
}

export function omitPermissiveLicenses(licenseSummary) {
  return licenseSummary.filter(license => {
    return !PermissiveLicenses.includes(license);
  });
}
