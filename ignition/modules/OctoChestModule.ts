import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OctoChestModule = buildModule("OctoChestModule", (m) => {
  const defaultAdmin = m.getParameter("defaultAdmin");
  const minter = m.getParameter("minter");

  const octoChest = m.contract("OctoChest", [defaultAdmin, minter], {});

  return { octoChest };
});

export default OctoChestModule;
