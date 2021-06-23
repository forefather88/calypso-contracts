const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const SC = artifacts.require("TestFaucet");

//Current proxy address: 0x0C1840E46F8283AC63242b5FC7206B0faD20b06B
module.exports = async function (deployer) {
  //Deploy
  //const instance = await deployProxy(SC, [], { deployer });
  //console.log("Deployed", instance.address);

  //Updrade
  await upgradeProxy("0x0C1840E46F8283AC63242b5FC7206B0faD20b06B", SC, {
    deployer,
  });
};
