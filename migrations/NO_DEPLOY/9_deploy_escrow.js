const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Escrow");

//Current proxy address: 0xa1bDAe43EdBB7031AF6269B21603E0B2f4ba1E07
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xa1bDAe43EdBB7031AF6269B21603E0B2f4ba1E07", SC, {
    deployer,
  });
};
