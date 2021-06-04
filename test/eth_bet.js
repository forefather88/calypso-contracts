const {
  stringToBytes32,
  byte32ToString,
  getEther,
  getWei,
} = require("./utils");
const initTest = require("./init_test");

const BettingPool = artifacts.require("BettingPool");

contract("Betting Pool 1", (accounts) => {
  it("Bet with ETH", async () => {
    const {
      poolManager,
      cal,
      escrow,
      staking,
      oracle,
      affiliate,
    } = await initTest();
    const ethAddr = "0x0000000000000000000000000000000000000000";
    // Set Operator
    await oracle.changeOperatorAddress(accounts[8]);

    // Set affiliate
    const numberAddr = "10";
    await cal.approve(affiliate.address, getWei(numberAddr));
    await affiliate.increaseNumberAddress(numberAddr);
    await affiliate.saveMultiAddrs([accounts[3], accounts[4]], []);
    const { _referrals } = await affiliate.getAffiliateStatus([ethAddr]);
    assert.equal(_referrals.length, 2, "Wrong number of referrals");

    // Staking
    var stakingAmount = "100";
    await cal.approve(staking.address, getWei(stakingAmount));
    await staking.stake(getWei(stakingAmount));
    assert.equal(getEther(await staking.stakeAmount(accounts[0])), 100);

    stakingAmount = "100";
    await cal.transfer(accounts[1], getWei(stakingAmount));
    await cal.approve(staking.address, getWei(stakingAmount), {
      from: accounts[1],
    });
    await staking.stake(getWei(stakingAmount), { from: accounts[1] });

    // Create pool
    const maxCap = "10000";
    await cal.approve(poolManager.address, getWei(maxCap));
    await poolManager.createBettingPool(
      "Champion Leage",
      "round1",
      100,
      "epl",
      1614854540,
      ethAddr,
      100,
      getWei(maxCap),
      []
    );
    const poolAddr = await poolManager.getLastOwnPool(0);
    const pool = await BettingPool.at(poolAddr);

    // Bet with Eth
    await pool.betWithEth(1, { from: accounts[3], value: getWei("2") });
    await pool.betWithEth(2, { from: accounts[4], value: getWei("4") });

    // Set result
    await pool.changeEndDate(1604213495);
    await pool.testSetResult(1, { from: accounts[8] });
    assert.equal(getEther(await pool.winOutcome()), 5.88, "Wrong out come");

    // Forward platform fee
    await pool.testforwardPlatformFee();
    const stakeResult = await staking.getCurrentState(accounts[0]);
    assert.equal(getEther(stakeResult._stakeIncome), 1.8, "Wrong stake income");

    // Forward affiliate award
    await pool.testforwardAffiliateAward();
    const award1 = await affiliate.getReward(ethAddr);
    assert.equal(getEther(award1), 0.075, "Wrong affiliate award");
  });
});
