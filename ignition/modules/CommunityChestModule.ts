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

  const level1Payout = m.getParameter("level1Payout");
  const level2Payout = m.getParameter("level2Payout");

  const redeemToken = m.getParameter("redeemToken");

  const redeemContract = m.contract("CommunityChestRedeem", [
    redeemToken,
    communityChest,
    level1Payout,
    level2Payout,
  ]);

  return { communityChest, marketPlace, redeemContract };
});

export default CommunityChestModule;
