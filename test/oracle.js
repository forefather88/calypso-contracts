const {
  stringToBytes32,
  byte32ToString,
  getEther,
  getWei,
  Zero,
} = require("./utils");
const Oracle = artifacts.require("Oracle");

contract("Oracle", (accounts) => {
  it("Get maxcap", async () => {
    const oracle = await Oracle.deployed();
    await oracle.enableManualInputPrice(true);
    const maxCap = await oracle.getMaxCap(
      getWei("1"),
      "0x0000000000000000000000000000000000000001"
    );
    assert.equal(maxCap.toString(), "18000000000000000000000000000");
  });
});
