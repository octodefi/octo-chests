import hre from "hardhat";
import path from "path";
import CommunityChestModule from "../ignition/modules/CommunityChestModule";

async function main() {
  const signer = (await hre.ethers.getSigners())[0];

  const signerAddress = await signer.getAddress();
  console.log("Deploying CommunityChestModule with signer: ", signerAddress);

  await hre.ignition.deploy(CommunityChestModule, {
    parameters: path.resolve(
      __dirname,
      `../ignition/parameters/parameters-${hre.network.name}.json`
    ),
    displayUi: true,
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
