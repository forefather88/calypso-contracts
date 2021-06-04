const {
  stringToBytes32,
  byte32ToString,
  getEther,
  getWei,
} = require("./utils");
const initTest = require("./init_test");

const BettingPool = artifacts.require("BettingPool");

contract("Betting Pool 0", (accounts) => {
  it("Test private pool", async () => {
    const { usdt, poolManager, cal, staking, escrow } = await initTest();

    // Transfer USDT
    await usdt.transfer(accounts[1], getWei("1000"));
    await usdt.transfer(accounts[2], getWei("2000"));

    // Create pool
    const maxCap = "10000";
    await cal.approve(poolManager.address, getWei(maxCap));
    await poolManager.createBettingPool(
      "Champion Leage",
      "round1",
      100,
      "epl",
      1614854540,
      usdt.address,
      10,
      getWei(maxCap),
      [accounts[0], accounts[1]]
    );
    const poolAddr = await poolManager.getLastOwnPool(0);
    const pool = await BettingPool.at(poolAddr);
    assert.equal(await pool.isPrivate(), true, "Should be private");

    // Place bet with tokens
    var amount = "100";
    await usdt.approve(poolAddr, getWei(amount), { from: accounts[0] });
    await pool.betWithToken(1, getWei(amount), { from: accounts[0] });
    var bets = await poolManager.getBetsInPool(poolAddr, { from: accounts[0] });
    assert.equal(bets.length, 1, "bet number wrong");

    var amount = "100";
    await usdt.approve(poolAddr, getWei(amount), { from: accounts[1] });
    await pool.betWithToken(1, getWei(amount), { from: accounts[1] });
    var bets = await poolManager.getBetsInPool(poolAddr, { from: accounts[1] });
    assert.equal(bets.length, 1, "bet number wrong");

    // account2 is not in whitelist
    amount = "200";
    await usdt.approve(poolAddr, getWei(amount), { from: accounts[2] });
    try {
      await pool.betWithToken(1, getWei(amount), { from: accounts[2] });
    } catch (err) {}
    var bets = await poolManager.getBetsInPool(poolAddr, { from: accounts[2] });
    assert.equal(bets.length, 0, "bet number wrong");
  });
});
