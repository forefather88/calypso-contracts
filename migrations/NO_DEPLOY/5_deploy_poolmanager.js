const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("PoolManager");

//Current proxy address: 0x213D91f2D98A5A7f4C53A8496f741912298F594D
module.exports = async function (deployer) {
  //Deploy
  //const instance = await deployProxy(SC, [], { deployer });
  //console.log("Deployed", instance.address);

  //Updrade
  await upgradeProxy("0x213D91f2D98A5A7f4C53A8496f741912298F594D", SC, {
    deployer,
  });
};
