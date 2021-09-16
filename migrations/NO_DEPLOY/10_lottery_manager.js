const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("LotteryManager");

//Current proxy address:0x71B7F9B0ee180f6689f0E85577e0931D92505758
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x71B7F9B0ee180f6689f0E85577e0931D92505758", SC, {
    deployer,
  });
};
