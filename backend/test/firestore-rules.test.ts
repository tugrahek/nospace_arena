import { readFile } from "node:fs/promises";
import { after, before, test } from "node:test";
import assert from "node:assert/strict";
import { assertFails, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import type { RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDoc, getDocs, runTransaction, setDoc, updateDoc, writeBatch } from "firebase/firestore";

const PROJECT_ID = "demo-nospace-wallet";
const paths = [
  "wallets/owner-a", "wallets/owner-a/ledger/credit-a",
  "wallets/owner-a/entitlements/character-drag", "purchases/purchase-a",
  "consumptionOutbox/purchase-a", "checkoutIntents/intent-a", "refunds/refund-a",
  "reviews/review-a", "tokenTombstones/purchase-a", "unrecognized/nested/path/document",
];
let env: RulesTestEnvironment;

before(async () => {
  // Refuse to run against a real project or accidentally fall back to production.
  assert.equal(process.env.GCLOUD_PROJECT, PROJECT_ID);
  assert.equal(process.env.FIRESTORE_EMULATOR_HOST, "127.0.0.1:8080");
  env = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { host: "127.0.0.1", port: 8080, rules: await readFile("firestore.rules", "utf8") },
  });
  await env.withSecurityRulesDisabled(async (context) => {
    for (const path of paths) {
      await setDoc(doc(context.firestore(), path), { uid: "owner-a", paidBalance: 500 });
    }
  });
});

after(async () => { if (env) await env.cleanup(); });

for (const identity of ["guest", "owner-a", "owner-b", "anonymous", "custom-admin"]) {
  test(`denies create/update/delete everywhere for ${identity}`, async () => {
    const context = identity === "guest" ? env.unauthenticatedContext() :
      env.authenticatedContext(identity === "owner-a" ? "owner-a" : identity, {
        firebase: { sign_in_provider: identity === "anonymous" ? "anonymous" : "google.com" },
        admin: identity === "custom-admin",
      });
    const db = context.firestore();
    for (const path of paths) {
      await assertFails(setDoc(doc(db, `${path}-new`), { uid: "owner-a", paidBalance: 99999 }));
      await assertFails(setDoc(doc(db, path), { uid: "owner-b", paidBalance: 99999 }));
      await assertFails(updateDoc(doc(db, path), { paidBalance: 99999 }));
      await assertFails(deleteDoc(doc(db, path)));
    }
  });
}

test("even a Google-authenticated owner cannot read wallet, ledger, tokens or unlocks directly", async () => {
  const db = env.authenticatedContext("owner-a", { firebase: { sign_in_provider: "google.com" } }).firestore();
  for (const path of paths) await assertFails(getDoc(doc(db, path)));
  await assertFails(getDocs(collection(db, "wallets")));
  await assertFails(getDocs(collection(db, "wallets/owner-a/ledger")));
});

test("guest and another account cannot read private server records", async () => {
  for (const context of [env.unauthenticatedContext(), env.authenticatedContext("owner-b")]) {
    for (const path of paths) await assertFails(getDoc(doc(context.firestore(), path)));
  }
});

test("client batches and transactions cannot mint coins or install paid entitlements", async () => {
  const db = env.authenticatedContext("owner-a").firestore();
  const batch = writeBatch(db);
  batch.set(doc(db, "wallets/owner-a"), { paidBalance: 99999 });
  batch.set(doc(db, "wallets/owner-a/entitlements/character-halt"), { status: "active" });
  await assertFails(batch.commit());
  await assertFails(runTransaction(db, async (transaction) => {
    transaction.set(doc(db, "wallets/owner-a"), { paidBalance: 99999 });
  }));
});

test("denied mutations leave server fixture balance and ownership intact", async () => {
  await env.withSecurityRulesDisabled(async (context) => {
    const data = (await getDoc(doc(context.firestore(), "wallets/owner-a"))).data();
    assert.deepEqual(data, { uid: "owner-a", paidBalance: 500 });
    assert.equal((await getDoc(doc(context.firestore(), "wallets/owner-a-new"))).exists(), false);
    assert.equal((await getDoc(doc(context.firestore(), "wallets/owner-a/entitlements/character-halt"))).exists(), false);
  });
});
