const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Staking");

//Current proxy address:0x482C1206a89F5B3a20e49318185F3fc6a7444842
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x482C1206a89F5B3a20e49318185F3fc6a7444842", SC, {
    deployer,
  });
};
