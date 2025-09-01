import { task } from "hardhat/config";

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getDeployedAddress } from "../utils/getDeployedAddress";

task("transfer-ownership", "Transfer ownership of a contract to a new address")
  .addParam("newowner", "The address of the new owner")
  .setAction(
    async (taskArgs: { newowner: string }, hre: HardhatRuntimeEnvironment) => {
      const { newowner: newOwner } = taskArgs;

      const { chainId } = await hre.ethers.provider.getNetwork();

      const marketPlaceAddress = getDeployedAddress(
        "CommunityChestModule",
        "Marketplace",
        Number(chainId)
      );

      const marketplaceContract = await hre.ethers.getContractAt(
        "Marketplace",
        marketPlaceAddress
      );
      await marketplaceContract.transferOwnership(newOwner);
      console.log(`Ownership of marketplace transferred to ${newOwner}`);
    }
  );
