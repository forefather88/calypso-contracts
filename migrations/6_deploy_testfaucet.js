
const SC = artifacts.require('TestFaucet');

module.exports = async function (deployer) {
  // const instance = await deployProxy(SC, [], { deployer });
  // console.log('Deployed', instance.address);
  await deployer.deploy(SC);
};