const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Staking");

//Current proxy address: 0x7ECbCA800c103688eFa03b60553AA6489a225643
module.exports = async function (deployer) {
  //Deploy
  const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);

  //Updrade
  /*await upgradeProxy("0x7ECbCA800c103688eFa03b60553AA6489a225643", SC, {
    deployer,
  });*/
};
