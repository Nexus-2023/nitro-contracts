import { ethers, run } from "hardhat"
import {
    abi as UpgradeExecutorABI,
    bytecode as UpgradeExecutorBytecode,
  } from '@offchainlabs/upgrade-executor/build/contracts/src/UpgradeExecutor.sol/UpgradeExecutor.json'
import { maxDataSize } from "./config";
import { deployContract } from "./deploymentUtils";
import { Toolkit4844 } from "../test/contract/toolkit4844";


async function main() {
    const ExecutorContract = "0x8d8fc75DCFCD9586e4721F2452C6aFfaF71f1233";
    const SequencerInboxProxy = "0x33D3A8042c4d8B8a28b51AB102d684211Bd85B80";
    const ProxyAdmin = "0xf9d3f8d16f7eb8a096f7ec557a7413bfedd350a3";
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

    const upgrade = upgradeExecutorFactory.attach(ExecutorContract);
    var tx = await upgrade.executeCall(ProxyAdmin, proxyAdmin.interface.encodeFunctionData("upgrade", [SequencerInboxProxy, sequencerInbox.address]));


    console.log(tx.hash)
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })

