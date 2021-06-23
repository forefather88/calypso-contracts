const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Oracle");

//Current proxy address: 0xbbf297ee562b11544802c055e9f5EB91E53E06d8
module.exports = async function (deployer) {
  //Deploy
  //const instance = await deployProxy(SC, [], { deployer });
  //console.log("Deployed", instance.address);

  //Updrade
  await upgradeProxy("0xbbf297ee562b11544802c055e9f5EB91E53E06d8", SC, {
    deployer,
  });
};
