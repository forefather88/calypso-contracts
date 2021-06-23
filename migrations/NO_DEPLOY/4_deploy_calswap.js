const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("CalSwap");

//Current proxy address: 0x476E489d8671216fE22ea24e6A300Ec2fF0A4470
module.exports = async function (deployer) {
  //Deploy
  //const instance = await deployProxy(SC, [], { deployer });
  //console.log("Deployed", instance.address);

  //Updrade
  await upgradeProxy("0x476E489d8671216fE22ea24e6A300Ec2fF0A4470", SC, {
    deployer,
  });
};
