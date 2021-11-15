const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("LotteryManager");

//Current proxy address:0x2E3F964fefdf267AC594B4CD9F923dEB30A76640
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);/*

  //Updrade
  await upgradeProxy("0x2E3F964fefdf267AC594B4CD9F923dEB30A76640", SC, {
    deployer,
  });
};
