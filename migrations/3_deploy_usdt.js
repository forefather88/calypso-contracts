const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Usdt = artifacts.require('USDT');

module.exports = async function (deployer) {
  // const instance = await deployProxy(Usdt, [], { deployer });
  // console.log('Deployed', instance.address);
  await deployer.deploy(Usdt);
};