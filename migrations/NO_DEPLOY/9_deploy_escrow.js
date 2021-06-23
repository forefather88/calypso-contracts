const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("Escrow");

//Current proxy address: 0x8b283930dFe61888EEdadE68cb01938d16216884
module.exports = async function (deployer) {
  //Deploy
  //const instance = await deployProxy(SC, [], { deployer });
  //console.log("Deployed", instance.address);

  //Updrade
  await upgradeProxy("0x8b283930dFe61888EEdadE68cb01938d16216884", SC, {
    deployer,
  });
};
