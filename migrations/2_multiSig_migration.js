
const multiSigWallet = artifacts.require("myContract");

module.exports = function (deployer) {
  deployer.deploy(multiSigWallet);
};
