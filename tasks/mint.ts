import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getDeployedAddress } from "../utils/getDeployedAddress";

interface MintTaskArgs {
  to: string;
}

task("mint", "mint a new octo chest")
  .addParam("to", "the address to mint to")
  .setAction(async (taskArgs: MintTaskArgs, hre: HardhatRuntimeEnvironment) => {
    const { to } = taskArgs;

    const { chainId } = await hre.ethers.provider.getNetwork();

    const octoChestAddress = getDeployedAddress(
      "OctoChestModule",
      "OctoChest",
      Number(chainId)
    );

    const contract = await hre.ethers.getContractAt(
      "OctoChest",
      octoChestAddress
    );

    await contract.safeMint(to);

    console.log("Token successfull minted to", to);
  });
