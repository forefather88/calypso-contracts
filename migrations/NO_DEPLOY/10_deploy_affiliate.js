const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Affiliate");

//Current proxy address: 0xe0F702CFFc71Bb275Bcbe669a1429F2801972738
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  const instance = await upgradeProxy(
    "0xe0F702CFFc71Bb275Bcbe669a1429F2801972738",
    SC,
    { deployer }
  );
};
