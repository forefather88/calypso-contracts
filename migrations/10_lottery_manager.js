const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");

const SC = artifacts.require("LotteryManager");

//Current proxy address:0x6611C554321eB257964CB5F6AA93b8435064FB9D
module.exports = async function (deployer) {
  //Deploy
  // const instance = await deployProxy(SC, [], { deployer });
  // console.log("Deployed", instance.address);

  //Updrade
  await upgradeProxy("0x6611C554321eB257964CB5F6AA93b8435064FB9D", SC, {
    deployer,
  });
};
