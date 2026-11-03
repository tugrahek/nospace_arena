/** Server-owned grant catalog; never use client amounts or real-money prices. */
export const CATALOG_VERSION = 1 as const;
export const ANDROID_PACKAGE = "com.tugrahek.nospace" as const;
export const COIN_PACKS = Object.freeze({
  coins_500: 500,
  coins_1500: 1500,
  coins_4000: 4000,
} as const);
export type CoinSku = keyof typeof COIN_PACKS;

/** Accepts only exact approved SKU strings and a single integral unit. */
export function requireCoinPack(sku: unknown, quantity: unknown): Readonly<{
  sku: CoinSku;
  quantity: 1;
  coins: number;
  catalogVersion: typeof CATALOG_VERSION;
}> {
  if (typeof sku !== "string" || !Object.hasOwn(COIN_PACKS, sku) || quantity !== 1) {
    throw new Error("invalid-coin-pack");
  }
  const id = sku as CoinSku;
  return Object.freeze({ sku: id, quantity: 1, coins: COIN_PACKS[id], catalogVersion: CATALOG_VERSION });
}
