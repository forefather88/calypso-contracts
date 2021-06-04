const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SC = artifacts.require('PoolManager');

module.exports = async function (deployer) {
  // const instance = await deployProxy(SC, [], { deployer });
  // console.log('Deployed', instance.address);
  await deployer.deploy(SC);
};