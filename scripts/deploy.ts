import hre from "hardhat";
import path from "path";
import OctoChestModule from "../ignition/modules/OctoChestModule";

async function main() {
  const signer = (await hre.ethers.getSigners())[0];

  const signerAddress = await signer.getAddress();
  console.log("Deploying OctoChestModule with signer: ", signerAddress);

  await hre.ignition.deploy(OctoChestModule, {
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
