const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Cal = artifacts.require('Cal');

module.exports = async function (deployer) {
  // const instance = await deployProxy(Cal, [], { deployer });
  const instance = await deployer.deploy(Cal);
  // console.log('Deployed', instance.address);
};