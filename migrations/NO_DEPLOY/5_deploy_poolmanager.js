const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("PoolManager");

//Current proxy address: 0xb893f261BA2fd8aA0E3e04302B44b985e84Ef392
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xb893f261BA2fd8aA0E3e04302B44b985e84Ef392", SC, {
    deployer,
  });
};
