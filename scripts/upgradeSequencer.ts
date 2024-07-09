import { ethers, run } from "hardhat"
import {
    abi as UpgradeExecutorABI,
    bytecode as UpgradeExecutorBytecode,
  } from '@offchainlabs/upgrade-executor/build/contracts/src/UpgradeExecutor.sol/UpgradeExecutor.json'
import { maxDataSize } from "./config";
import { _isRunningOnArbitrum, deployContract } from "./deploymentUtils";
import { Toolkit4844 } from "../test/contract/toolkit4844";


async function main() {
    const ExecutorContract = "0x3b7800d1d946ab4B46ae986BA20F4CCe213D55b4";
    const SequencerInboxProxy = "0x0B0a949e7390CB3D15055383A58ce93c9FB07B9F";
    const ProxyAdmin = "0xd801c1DD86255e27C4af45571BabAC661Fc6Af86";
    const [admin] = await ethers.getSigners();

    const isOnArb = await _isRunningOnArbitrum(admin)
    const reader4844 = isOnArb ? ethers.constants.AddressZero : (await Toolkit4844.deployReader4844(admin)).address

    const proxyAdmin = await ethers.getContractFactory("ProxyAdmin");
    const proxyAdminFactory = proxyAdmin.attach(ProxyAdmin);
    const tx = await proxyAdminFactory.getProxyImplementation(SequencerInboxProxy)
    console.log("implementation Address (Initial): ", tx)
    
    const sequencerInbox = await deployContract('SequencerInbox', admin, [
        maxDataSize,
        reader4844,
        false,
      ])
    await sequencerInbox.deployed();
    console.log("sequencerInbox contract implementation:", sequencerInbox.address)

    const upgradeExecutorFactory = await ethers.getContractFactory(
        UpgradeExecutorABI,
        UpgradeExecutorBytecode
    )

    const upgrade = upgradeExecutorFactory.attach(ExecutorContract);

    const upgradeTx = await upgrade.executeCall(ProxyAdmin, proxyAdmin.interface.encodeFunctionData("upgrade", [SequencerInboxProxy, sequencerInbox.address]));
    console.log("upgrade Tx:", upgradeTx)

    const implementationTx = await proxyAdminFactory.getProxyImplementation(SequencerInboxProxy)
    console.log("implementation Address:", implementationTx)
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

