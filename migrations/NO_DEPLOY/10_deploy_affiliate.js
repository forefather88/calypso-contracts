const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Affiliate");

//Current proxy address: 0x3143aCDC37C8F3028C3feA288ea87C61411a4d28
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  const instance = await upgradeProxy(
    "0x3143aCDC37C8F3028C3feA288ea87C61411a4d28",
    SC,
    { deployer }
  );
  console.log("Upgraded", instance.address);
};
