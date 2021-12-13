const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("PoolManager");

//Current proxy address: 0xE785e81c8edE28266B177Dad2DF433ec718FD6BC
module.exports = async function (deployer) {
  //Deploy
  const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);

  //Updrade
  // await upgradeProxy("0xE785e81c8edE28266B177Dad2DF433ec718FD6BC", SC, {
  //   deployer,
  // });
};
