import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getDeployedAddress } from "../utils/getDeployedAddress";

interface PurchaseListingTaskArgs {
  nft: string;
  id: number;
}

task("purchase-listing")
  .addParam("nft")
  .addParam("id")
  .setAction(
    async (
      taskArgs: PurchaseListingTaskArgs,
      hre: HardhatRuntimeEnvironment
    ) => {
      const { nft, id } = taskArgs;

      const { chainId } = await hre.ethers.provider.getNetwork();

      const marketPlaceAddress = getDeployedAddress(
        "CommunityChestModule",
        "Marketplace",
        Number(chainId)
      );

      const contract = await hre.ethers.getContractAt(
        "Marketplace",
        marketPlaceAddress
      );

      const listing = await contract.getListing(nft, id);

      console.log(listing);

      if (listing.paymentToken === hre.ethers.ZeroAddress) {
        const trx = await contract.purchaseListing(nft, id, {
          value: listing.price,
        });

        await trx.wait();

        console.log(`Successfull purchased token ${id} - ${nft}!!!`);
      }
    }
  );
