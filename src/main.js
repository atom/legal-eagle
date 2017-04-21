import readInstalled from 'read-installed';
import {findLicenses, omitPermissiveLicenses} from './legal-eagle';

export default function legalEagle(options, cb) {
  const {path, overrides, omitPermissive} = options;

  return readInstalled(path, null, (err, packageData) => {
    if (err != null) {
      return cb(err);
    }

    try {
      const licenseSummary = overrides != null ? overrides : {};
      findLicenses(licenseSummary, packageData, path);

      if (omitPermissive) {
        omitPermissiveLicenses(licenseSummary);
      }

      return cb(null, licenseSummary);
    } catch (error) {
      return cb(error);
    }
  });
}
