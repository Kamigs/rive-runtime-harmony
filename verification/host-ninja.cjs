// Hvigor 6's native build task launches the SDK's Ninja directly, ignoring
// CMAKE_MAKE_PROGRAM. Keep the workaround local to this build process.
const childProcess = require('node:child_process');
const path = require('node:path');
const originalSpawn = childProcess.spawn;
childProcess.spawn = function (command, ...args) {
  if (process.env.RIVE_NINJA && typeof command === 'string' &&
      command.endsWith('/native/build-tools/cmake/bin/ninja')) {
    command = path.resolve(process.env.RIVE_NINJA);
  }
  return originalSpawn.call(this, command, ...args);
};
