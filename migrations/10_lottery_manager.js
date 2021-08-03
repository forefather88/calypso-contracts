const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("LotteryManager");

//Current proxy address: 0xE6237734d35fb6f91ecFD0a805fb069b67651613
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xE6237734d35fb6f91ecFD0a805fb069b67651613", SC, {
    deployer,
  });
};
