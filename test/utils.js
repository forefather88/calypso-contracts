module.exports = {
  stringToBytes32: (src) => {
    return web3.utils.padRight(web3.utils.asciiToHex(src), 32);
  },

  byte32ToString: (src) => {
    return web3.utils.hexToAscii(src);
  },

  getEther: (bn) => {
    return web3.utils.fromWei(bn);
  },

  getWei: (eth) => {
    return web3.utils.toWei(eth, "ether");
  },
};

exports.Zero = "0x0000000000000000000000000000000000000000";
