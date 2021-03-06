const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Oracle");

//Current proxy address: 0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xfFB0E212B568133fEf49d60f8d52b4aE4A2fdB72", SC, {
    deployer,
  });
};
