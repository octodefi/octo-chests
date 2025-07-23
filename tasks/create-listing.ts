import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getDeployedAddress } from "../utils/getDeployedAddress";

interface CreateListingTaskArgs {
  tokenid: number;
  price: string;
}

task("create-listing")
  .addParam("tokenid", "tokenid")
  .addParam("price", "price")
  .setAction(
    async (taskArgs: CreateListingTaskArgs, hre: HardhatRuntimeEnvironment) => {
      const { tokenid, price } = taskArgs;

      const { chainId } = await hre.ethers.provider.getNetwork();

      const marketPlaceAddress = getDeployedAddress(
        "OctoChestModule",
        "Marketplace",
        Number(chainId)
      );

      const octoChestAddress = getDeployedAddress(
        "OctoChestModule",
        "OctoChest",
        Number(chainId)
      );

      const chestContract = await hre.ethers.getContractAt(
        "OctoChest",
        octoChestAddress
      );

      const approveTrx = await chestContract.approve(
        marketPlaceAddress,
        tokenid
      );

      await approveTrx.wait();

      console.log("approve trx", approveTrx.hash);

      const parsedPrice = hre.ethers.parseEther(price);

      const contract = await hre.ethers.getContractAt(
        "Marketplace",
        marketPlaceAddress
      );

      const trx = await contract.createListing(tokenid, parsedPrice);

      await trx.wait();

      console.log("listing created");
    }
  );
