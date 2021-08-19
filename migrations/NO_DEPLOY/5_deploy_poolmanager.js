const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("PoolManager");

//Current proxy address: 0x36D25D7eDcf669552903127403542922fAdcfDd1
module.exports = async function (deployer) {
  //Deploy
  /* const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x36D25D7eDcf669552903127403542922fAdcfDd1", SC, {
    deployer,
  });
};
