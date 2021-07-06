const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("CalSwap");

//Current proxy address: 0x702AD4Cf93Dd3a6FBD8dF64679e280F7F4eEFE95
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x702AD4Cf93Dd3a6FBD8dF64679e280F7F4eEFE95", SC, {
    deployer,
  });
};
