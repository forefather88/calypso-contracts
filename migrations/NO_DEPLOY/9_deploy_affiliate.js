const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Affiliate");

//Current proxy address:
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  const instance = await upgradeProxy(
    "0x2752Fbff6C1289b90fbbCD8db9E8aDFb7c459Ed0",
    SC,
    { deployer }
  );
};
