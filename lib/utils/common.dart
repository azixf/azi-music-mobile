/// compare local app version with the remote one
bool compareVersion(String latestVersion, String currentVersion) {
  bool update = false;
  final List latestList = latestVersion.split('.');
  final List currentList = currentVersion.split('');

  for (int i = 0; i < latestList.length; i++) {
    try {
      if (int.parse(latestList[i]) > int.parse(currentList[i])) {
        update = true;
        break;
      }
    } catch (e) {
      break;
    }
  }
  return update;
}
