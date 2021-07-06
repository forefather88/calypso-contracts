const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("PoolManager");

//Current proxy address: 0xd765C0068D837E8Cba446c48cC2cc05a0417b163
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0xd765C0068D837E8Cba446c48cC2cc05a0417b163", SC, {
    deployer,
  });
};
