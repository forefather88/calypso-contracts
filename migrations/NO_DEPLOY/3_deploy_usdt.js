const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("USDT");

//Current proxy address: 0x896C84068fa31Af023f7A12170e78c42A07C6dD6
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x896C84068fa31Af023f7A12170e78c42A07C6dD6", SC, {
    deployer,
  });
};
