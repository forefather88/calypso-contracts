const {stringToBytes32, byte32ToString, getEther, getWei} = require('./utils');
const initTest = require('./init_test');

contract('Swap', async accounts => {
    it ("Swap Eth", async () => {
        const {calSwap, cal, oracle} = await initTest();
        var bal1 = getEther(await cal.balanceOf(accounts[0]));
        await web3.eth.sendTransaction({from: accounts[0], to: calSwap.address, value: getWei('1')});
        var bal2 = getEther(await cal.balanceOf(accounts[0]));
        const ethPrice = (await oracle.getEthPrice()) / 1e8;
        assert.equal(bal2 - bal1, ethPrice);
    })

    it ('Swap tokens', async () => {
        const {usdt, calSwap, cal} = await initTest();
        const amount = '100';
        await usdt.approve(calSwap.address, getWei(amount));
        var bal1 = getEther(await cal.balanceOf(accounts[0]));
        await calSwap.swap(getWei(amount));
        var bal2 = getEther(await cal.balanceOf(accounts[0]));
        assert.equal(bal2 - bal1, amount);
    })
})