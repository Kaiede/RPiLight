const core = require('@actions/core')
const path = require('path')
const {exec} = require('@actions/exec')

async function main() {
  if (process.platform === 'linux') {
    const version = core.getInput('version', {required: true})
    const distro = core.getInput('distribution', {required: true})

    console.log('Installing Swift ${version} for ${distro}')
    await exec(path.join(__dirname, 'install-swift.sh'),[version,distro])
  } else {
    throw new Error('install-swift supports only Linux')
  }
}

main().catch(err => {
  core.setFailed(err.message)
})
