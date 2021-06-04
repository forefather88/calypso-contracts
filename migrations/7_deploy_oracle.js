const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const Oracle = artifacts.require('Oracle');

module.exports = async function (deployer) {
  await deployer.deploy(Oracle);
};