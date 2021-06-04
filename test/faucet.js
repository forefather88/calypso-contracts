const {stringToBytes32, byte32ToString, getEther, getWei} = require('./utils');
const initTest = require('./init_test');

contract('Faucet', accounts => {
    it ("Get Usdt", async () => {
        const {testFaucet, usdt} = await initTest();

        var bal1 = getEther(await usdt.balanceOf(accounts[0]));
        await testFaucet.transferUsdt(getWei('120'))
        var bal2 = getEther(await usdt.balanceOf(accounts[0]));
        assert.equal(bal2 - bal1, 120);
    })
})