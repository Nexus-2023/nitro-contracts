import { ethers, run } from "hardhat"
import {
    abi as UpgradeExecutorABI,
    bytecode as UpgradeExecutorBytecode,
  } from '@offchainlabs/upgrade-executor/build/contracts/src/UpgradeExecutor.sol/UpgradeExecutor.json'
import { maxDataSize } from "./config";
import { deployContract } from "./deploymentUtils";
import { Toolkit4844 } from "../test/contract/toolkit4844";


async function main() {
    const ExecutorContract = "0xF9D3F8d16f7eb8A096f7ec557a7413BFeDD350A3";
    const SequencerInboxProxy = "0x33D3A8042c4d8B8a28b51AB102d684211Bd85B80";
    const ProxyAdmin = "0xEE5Ba29bFE35f584C06a0210405ADe7114ddC749";
    const [admin] = await ethers.getSigners();
    const reader4844 = (await Toolkit4844.deployReader4844(admin)).address

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

    const proxyAdmin = await ethers.getContractFactory("ProxyAdmin");
    const proxyAdminFactory = proxyAdmin.attach(ProxyAdmin);
    const tx = await proxyAdminFactory.getProxyImplementation(SequencerInboxProxy)
    console.log("tx: ", tx)

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

