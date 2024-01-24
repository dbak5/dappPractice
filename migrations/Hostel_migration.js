const Migrations = artifacts.require("Hostel");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};
