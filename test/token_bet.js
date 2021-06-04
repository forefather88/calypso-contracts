const {
  stringToBytes32,
  byte32ToString,
  getEther,
  getWei,
} = require("./utils");
const initTest = require("./init_test");
const BettingPool = artifacts.require("BettingPool");

contract("Betting pool 2", (accounts) => {
  it("Bet with tokens", async () => {
    const {
      usdt,
      poolManager,
      cal,
      staking,
      escrow,
      oracle,
      affiliate,
    } = await initTest();

    // Set Operator
    await oracle.changeOperatorAddress(accounts[8]);

    // Set affiliate
    const numberAddr = "10";
    await cal.approve(affiliate.address, getWei(numberAddr));
    await affiliate.increaseNumberAddress(numberAddr);
    await affiliate.saveMultiAddrs([accounts[3], accounts[4]], []);
    const { _referrals } = await affiliate.getAffiliateStatus([usdt.address]);
    assert.equal(_referrals.length, 2, "Wrong number of referrals");

    // Staking
    var stakingAmount = "100";
    await cal.approve(staking.address, getWei(stakingAmount));
    await staking.stake(getWei(stakingAmount));
    assert.equal(getEther(await staking.stakeAmount(accounts[0])), 100);

    stakingAmount = "200";
    await cal.transfer(accounts[1], getWei(stakingAmount));
    await cal.approve(staking.address, getWei(stakingAmount), {
      from: accounts[1],
    });
    await staking.stake(getWei(stakingAmount), { from: accounts[1] });

    // Transfer USDT
    await usdt.transfer(accounts[1], getWei("1000"));
    await usdt.transfer(accounts[2], getWei("2000"));
    await usdt.transfer(accounts[3], getWei("3000"));
    await usdt.transfer(accounts[4], getWei("2000"));
    await usdt.transfer(accounts[5], getWei("3000"));

    // Create pool
    const depositedCal = "20";
    const maxCap = "10000";
    await cal.approve(poolManager.address, getWei(maxCap));
    await poolManager.createBettingPool(
      "Champion Leage",
      "round1",
      100,
      "epl",
      1617353171,
      usdt.address,
      10,
      getWei(depositedCal),
      getWei(maxCap),
      []
    );
    const poolAddr = await poolManager.getLastOwnPool(0);
    const pool = await BettingPool.at(poolAddr);

    // Place bet with tokens
    var amount = "200";
    await usdt.approve(poolAddr, getWei(amount), { from: accounts[3] });
    await pool.betWithToken(1, getWei(amount), { from: accounts[3] });
    amount = "400";
    await usdt.approve(poolAddr, getWei(amount), { from: accounts[4] });
    await pool.betWithToken(2, getWei(amount), { from: accounts[4] });

    // Set result
    await pool.changeEndDate(1604213495);
    await pool.testSetResult(1, { from: accounts[8] });
    assert.equal(getEther(await pool.winOutcome()), 593.4, "Wrong out come");

    // Forward platform fee
    await pool.testforwardPlatformFee();
    const stakeResult = await staking.getCurrentState(accounts[0]);
    assert.equal(getEther(stakeResult._stakeIncome), 0.2, "Wrong stake income");

    // Forward affiliate award
    await pool.testforwardAffiliateAward();
    const award1 = await affiliate.getReward(usdt.address);
    assert.equal(getEther(award1), 7.5, "Wrong affiliate award");
  });
});
