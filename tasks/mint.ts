import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { getDeployedAddress } from "../utils/getDeployedAddress";

interface MintTaskArgs {
  to: string;
  lvl: number;
}

task("mint", "mint a new octo chest")
  .addParam("to", "the address to mint to")
  .addParam("lvl", "level of the token (1 or 2)")
  .setAction(async (taskArgs: MintTaskArgs, hre: HardhatRuntimeEnvironment) => {
    const { to, lvl } = taskArgs;

    const { chainId } = await hre.ethers.provider.getNetwork();

    const octoChestAddress = getDeployedAddress(
      "OctoChestModule",
      "OctoChest",
      Number(chainId)
    );

    const signer = (await hre.ethers.getSigners())[0];

    const signerAddress = await signer.getAddress();

    const contract = await hre.ethers.getContractAt(
      "OctoChest",
      octoChestAddress
    );

    const minterRole = await contract.MINTER_ROLE();

    const isMinter = await contract.hasRole(minterRole, signerAddress);

    if (!isMinter) {
      console.log("Account is not minter. Grant Minter rights");
      await contract.grantRole(minterRole, signerAddress);
    }

    if (lvl > 2 || lvl == 0) {
      console.log("Not Possible to mint this lvl");
    } else {
      let trx;
      if (lvl == 1) {
        trx = await contract.safeMintLevel1(to);
      } else {
        trx = await contract.safeMintLevel2(to);
      }
      console.log("Token successfull minted to", to);
      console.log("transaction", trx.hash);
    }
  });
