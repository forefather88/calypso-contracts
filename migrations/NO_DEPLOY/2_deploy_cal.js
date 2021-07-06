const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Cal");

//Current proxy address: 0x36DF4070E048A752C5abD7eFD22178ce8ef92535
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x36DF4070E048A752C5abD7eFD22178ce8ef92535", SC, {
    deployer,
  });
};
