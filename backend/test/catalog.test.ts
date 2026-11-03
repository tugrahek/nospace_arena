import assert from "node:assert/strict";
import { test } from "node:test";
import { ANDROID_PACKAGE, CATALOG_VERSION, COIN_PACKS, requireCoinPack } from "../src/catalog.js";

test("catalog contains exactly the three approved one-unit coin amounts", () => {
  assert.equal(ANDROID_PACKAGE, "com.tugrahek.nospace");
  assert.equal(CATALOG_VERSION, 1);
  assert.deepEqual(COIN_PACKS, { coins_500: 500, coins_1500: 1500, coins_4000: 4000 });
  for (const [sku, coins] of Object.entries(COIN_PACKS)) {
    assert.deepEqual(requireCoinPack(sku, 1), { sku, quantity: 1, coins, catalogVersion: 1 });
  }
});

test("rejects unsupported, non-string, normalized and prototype-property SKUs", () => {
  for (const sku of [undefined, null, 500, {}, ["coins_500"], "", "coins_1000",
    "coins_500 ", " coins_500", "COINS_500", "__proto__", "constructor", "toString"]) {
    assert.throws(() => requireCoinPack(sku, 1), /invalid-coin-pack/);
  }
});

test("quantity must be exactly numeric one; no coercion, fractions or multi-quantity", () => {
  for (const quantity of [undefined, null, "1", true, 0, -1, 2, 1.5, NaN, Infinity, {}, [1]]) {
    assert.throws(() => requireCoinPack("coins_500", quantity), /invalid-coin-pack/);
  }
});

test("client mutation cannot change the frozen server catalog or later grants", () => {
  assert.equal(Object.isFrozen(COIN_PACKS), true);
  const grant = requireCoinPack("coins_500", 1);
  assert.equal(Object.isFrozen(grant), true);
  assert.equal(Reflect.set(COIN_PACKS, "coins_500", 99999), false);
  assert.equal(Reflect.set(grant, "coins", 99999), false);
  assert.equal(requireCoinPack("coins_500", 1).coins, 500);
});
