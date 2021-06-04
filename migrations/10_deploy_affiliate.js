const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const SC = artifacts.require('Affiliate');

module.exports = async function (deployer) {
  await deployer.deploy(SC);
};