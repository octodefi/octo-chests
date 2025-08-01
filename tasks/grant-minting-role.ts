import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getDeployedAddress } from "../utils/getDeployedAddress";

interface GrantMintingRoleTaskArgs {
  minter: string;
}

task("grant-minting-role")
  .addParam("minter", "address of the new minter")
  .setAction(
    async (
      taskArgs: GrantMintingRoleTaskArgs,
      hre: HardhatRuntimeEnvironment
    ) => {
      const { minter } = taskArgs;

      const { chainId } = await hre.ethers.provider.getNetwork();

      const communityChestAddress = getDeployedAddress(
        "CommunityChestModule",
        "CommunityChest",
        Number(chainId)
      );

      const chestContract = await hre.ethers.getContractAt(
        "CommunityChest",
        communityChestAddress
      );

      const mintingRole = await chestContract.MINTER_ROLE();

      const trx = await chestContract.grantRole(mintingRole, minter);

      await trx.wait();

      console.log(`Grant address ${minter} minting rights!`);
    }
  );
