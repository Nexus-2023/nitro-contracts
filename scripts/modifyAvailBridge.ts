import { ethers } from "hardhat";
import { _isRunningOnArbitrum } from "./deploymentUtils";
import {
  abi as UpgradeExecutorABI,
  bytecode as UpgradeExecutorBytecode,
} from '@offchainlabs/upgrade-executor/build/contracts/src/UpgradeExecutor.sol/UpgradeExecutor.json'
import { config } from "./config";

async function main () {
    const ExecutorContract = "0x3b7800d1d946ab4B46ae986BA20F4CCe213D55b4";
    const SequencerInboxProxy = "0x0B0a949e7390CB3D15055383A58ce93c9FB07B9F";
    const AvailBridgeAddress = "0xa3e9e20875b7A7461C4829663497F7c2baB9E13b";

    const sequencerInbox = await ethers.getContractFactory("SequencerInbox");
    const sequencerInboxFactory = sequencerInbox.attach(SequencerInboxProxy);
    const bridge = await sequencerInboxFactory.bridge();

    console.log("avail Bridge:", await sequencerInboxFactory.availBridge());
    console.log("bridge:", bridge);

    const upgradeExecutorFac = await ethers.getContractFactory(
      UpgradeExecutorABI,
      UpgradeExecutorBytecode
    )

    const upgrade = await upgradeExecutorFac.attach(ExecutorContract);

    var tx = await upgrade.executeCall(SequencerInboxProxy, sequencerInbox.interface.encodeFunctionData(
      "setAvailBridgeAddress", 
      [AvailBridgeAddress]));

    console.log("tx Hash:", tx.hash)

    console.log("avail Bridge (modified):", await sequencerInboxFactory.availBridge());

}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })
