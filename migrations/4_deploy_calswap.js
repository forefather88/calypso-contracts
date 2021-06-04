const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const CalSwap = artifacts.require('CalSwap');

module.exports = async function (deployer) {
  // const instance = await deployProxy(CalSwap, [], { deployer });
  // console.log('Deployed', instance.address);
  await deployer.deploy(CalSwap);
};