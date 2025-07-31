import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const CommunityChestModule = buildModule("CommunityChestModule", (m) => {
  const defaultAdmin = m.getParameter("defaultAdmin");
  const minter = m.getParameter("minter");

  const communityChest = m.contract(
    "CommunityChest",
    [defaultAdmin, minter],
    {}
  );

  const fee = m.getParameter("fee");

  const paymentsTokens = m.getParameter("paymentTokens");

  const marketPlace = m.contract("Marketplace", [fee, paymentsTokens]);

  return { communityChest, marketPlace };
});

export default CommunityChestModule;
