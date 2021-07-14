const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Affiliate");

//Current proxy address:
module.exports = async function (deployer) {
  //Deploy
  const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);

  //Updrade
  /*const instance = await upgradeProxy(
    "",
    SC,
    { deployer }
  );*/
};
