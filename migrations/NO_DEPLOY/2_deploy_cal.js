const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Cal");

//Current proxy address: 0xec0A5D38c5C65Ee775d28aBf412ea2C5ffa76728
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xec0A5D38c5C65Ee775d28aBf412ea2C5ffa76728", SC, {
    deployer,
  });
};
