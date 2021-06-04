const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SC = artifacts.require('Staking');

module.exports = async function (deployer) {
  await deployer.deploy(SC);
};