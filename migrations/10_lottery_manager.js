const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("LotteryManager");

//Current proxy address:0xf05D2ec5C7DA96C1C831ed28bB98E93BA75931c9
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xf05D2ec5C7DA96C1C831ed28bB98E93BA75931c9", SC, {
    deployer,
  });
};
