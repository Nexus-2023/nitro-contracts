import { ethers,run } from 'hardhat';
import {
  abi as UpgradeExecutorABI,
  bytecode as UpgradeExecutorBytecode,
} from '@offchainlabs/upgrade-executor/build/contracts/src/UpgradeExecutor.sol/UpgradeExecutor.json'
export async function verifyContract(
  contractAddress: string,
  constructorArguments: any
) {
  await run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArguments,
  });
}
async function main() {
  const ExecutorContract = "0xda8636b0d4f31e87d6e7abe1eaa7a17caa9bc487";
  const ProxyAdmin = "0x1633e1BFb0F2f4A1A13Cde3B815C8009d54B070c";
  const BridgeProxy = "0x85deaBEa8c6b45ff1f21C128b1f6Ed971bC122b3";
  const [admin] = await ethers.getSigners();
  const RollupBridge = await ethers.getContractFactory("Bridge");
  const bridge = await RollupBridge.deploy();
  await bridge.deployed();
  console.log("bridge contract implementation:", bridge.address)
  const upgradeExecutorFac = await ethers.getContractFactory(
    UpgradeExecutorABI,
    UpgradeExecutorBytecode
  )
  const proxyAdmin = await ethers.getContractFactory("ProxyAdmin");
  const upgrade = await upgradeExecutorFac.attach(ExecutorContract);
  var tx = await upgrade.executeCall(ProxyAdmin,proxyAdmin.interface.encodeFunctionData("upgrade",["0x85deaBEa8c6b45ff1f21C128b1f6Ed971bC122b3",bridge.address]));
  console.log(tx.hash)
  console.log("verifying contracts")
  await verifyContract(bridge.address,[])


  // console.log(hash);
  // var value = await ethers.provider.getStorageAt("0x1633e1BFb0F2f4A1A13Cde3B815C8009d54B070c","0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103");
  // var value_2 = await ethers.provider.getStorageAt("0x1f36f44a377C0D48706F0726608724d1E884D5c7","0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc");
  // await verifyContract("0x1f36f44a377C0D48706F0726608724d1E884D5c7",["0xd1c2758d3607b4847b4c6ba159b7cc700497e5a","0xda8636b0d4f31e87d6e7abe1eaa7a17caa9bc487"])
  // console.log("admin",value);
  // console.log("logic:",value_2);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error)
    process.exit(1)
  })
