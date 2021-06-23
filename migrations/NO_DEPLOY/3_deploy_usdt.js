const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("USDT");

//Current proxy address: 0x679D993290D209a2Ccb6cd9F5a42A6302c41B1Ea
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x679D993290D209a2Ccb6cd9F5a42A6302c41B1Ea", SC, {
    deployer,
  });
};
