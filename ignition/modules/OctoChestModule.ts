import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OctoChestModule = buildModule("OctoChestModule", (m) => {
  const defaultAdmin = m.getParameter("defaultAdmin");
  const minter = m.getParameter("minter");

  const octoChest = m.contract("OctoChest", [defaultAdmin, minter], {});

  const fee = m.getParameter("fee");

  const paymentsTokens = m.getParameter("paymentTokens");

  const marketPlace = m.contract("Marketplace", [
    octoChest,
    fee,
    paymentsTokens,
  ]);

  return { octoChest, marketPlace };
});

export default OctoChestModule;
