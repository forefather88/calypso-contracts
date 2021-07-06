const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const SC = artifacts.require("TestFaucet");

//Current proxy address: 0x6a63Cf2AEB160429bd75c625C9a33b43068dB85f
module.exports = async function (deployer) {
  //Deploy
  /*const instance = await deployProxy(SC, [], { deployer });
  console.log("Deployed", instance.address);*/

  //Updrade
  await upgradeProxy("0x6a63Cf2AEB160429bd75c625C9a33b43068dB85f", SC, {
    deployer,
  });
};
