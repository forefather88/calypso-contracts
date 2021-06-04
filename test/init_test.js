const {stringToBytes32, byte32ToString, getEther, getWei} = require('./utils');
const Usdt = artifacts.require('USDT');
const CalSwap = artifacts.require('CalSwap');
const Cal = artifacts.require('Cal');
const Oracle = artifacts.require('Oracle');
const PoolManager = artifacts.require('PoolManager');
const TestFaucet = artifacts.require('TestFaucet');
const Staking = artifacts.require('Staking');
const Escrow = artifacts.require('Escrow');
const Affiliate = artifacts.require('Affiliate');

module.exports = async () => {
    const usdt = await Usdt.deployed();
    const calSwap = await CalSwap.deployed();
    const cal = await Cal.deployed();
    const oracle = await Oracle.deployed();
    const poolManager = await PoolManager.deployed();
    const testFaucet = await TestFaucet.deployed();
    const staking = await Staking.deployed();
    const escrow = await Escrow.deployed();
    const affiliate = await Affiliate.deployed();

    await oracle.changeCalAddress(cal.address);
    await oracle.changeUsdtAddress(usdt.address);
    await oracle.changeEscrowAddress(escrow.address);
    await oracle.changeStakingAddress(staking.address);
    await oracle.changeAffiliateAddress(affiliate.address);
    
    await calSwap.changeOracle(oracle.address);
    await poolManager.changeOracle(oracle.address);
    await testFaucet.changeOracle(oracle.address);
    await staking.changeOracle(oracle.address);
    await escrow.changeOracle(oracle.address);
    await affiliate.changeOracle(oracle.address);

    // Init Cal Swap
    await cal.transfer(calSwap.address, getWei('12300'));

    // Init Test Faucet
    await usdt.transfer(testFaucet.address, getWei('34500'));

    // Init Test Escrow
    await cal.transfer(escrow.address, getWei('45600'));

    return {usdt, calSwap, cal, oracle, testFaucet, poolManager, staking, escrow, affiliate};
}