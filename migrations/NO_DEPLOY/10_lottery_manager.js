const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("LotteryManager");

//Current proxy address:0xfFB1726C4c600471d4529286553cE315234eeBE8
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xfFB1726C4c600471d4529286553cE315234eeBE8", SC, {
    deployer,
  });
};
