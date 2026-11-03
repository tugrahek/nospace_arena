import assert from "node:assert/strict";
import { test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import type { DecodedIdToken } from "firebase-admin/auth";
import { AuthenticationError, requireGooglePrincipal } from "../src/auth.js";
import type { TokenVerifier } from "../src/auth.js";

function claims(provider = "google.com", uid = "owner-a"): DecodedIdToken {
  return {
    aud: "demo-nospace-wallet", iss: "https://securetoken.google.com/demo-nospace-wallet",
    sub: uid, uid, iat: 1, exp: 2, auth_time: 1,
    firebase: { sign_in_provider: provider, identities: {} },
  };
}

function accepting(decoded = claims()): TokenVerifier {
  return { async verifyIdToken() { return decoded; } };
}

test("requires Admin verification with revocation enabled and returns verified UID only", async () => {
  const calls: unknown[][] = [];
  const verifier: TokenVerifier = {
    async verifyIdToken(...args) { calls.push(args); return claims(); },
  };
  const principal = await requireGooglePrincipal("Bearer opaque-test-token", verifier);
  assert.deepEqual(calls, [["opaque-test-token", true]]);
  assert.deepEqual(principal, { uid: "owner-a", provider: "google.com" });
  assert.equal(Object.isFrozen(principal), true);
});

test("missing, malformed and multiple authorization values fail before verification", async () => {
  let calls = 0;
  const verifier: TokenVerifier = {
    async verifyIdToken() { calls++; return claims(); },
  };
  for (const header of [undefined, null, 5, [], ["Bearer x"], "", "x", "Bearer",
    "Bearer ", "bearer x", "Bearer x y", "Bearer x\n", " Bearer x", "Bearer x, Bearer y"]) {
    await assert.rejects(requireGooglePrincipal(header, verifier), AuthenticationError);
  }
  assert.equal(calls, 0);
});

for (const reason of ["expired", "revoked", "disabled", "wrong-audience", "bad-signature"]) {
  test(`rejects verifier failure: ${reason}, without exposing sensitive input`, async () => {
    const verifier: TokenVerifier = {
      async verifyIdToken() { throw new Error(`secret-token:${reason}`); },
    };
    await assert.rejects(requireGooglePrincipal("Bearer secret-token", verifier), (error: unknown) => {
      assert.ok(error instanceof AuthenticationError);
      assert.equal(error.message, "unauthenticated");
      assert.equal(error.stack?.includes("secret-token"), false);
      assert.equal(Object.hasOwn(error, "cause"), false);
      return true;
    });
  });
}

test("rejects anonymous, password, custom and other-provider sessions", async () => {
  for (const provider of ["anonymous", "password", "custom", "apple.com", ""]) {
    await assert.rejects(requireGooglePrincipal("Bearer token", accepting(claims(provider))), AuthenticationError);
  }
});

test("rejects empty, oversized and unsafe document UIDs", async () => {
  for (const uid of ["", " ", "../owner", "a/b", ".", "..", "x".repeat(129)]) {
    await assert.rejects(requireGooglePrincipal("Bearer token", accepting(claims("google.com", uid))), AuthenticationError);
  }
});

test("real Admin SDK rejects an unsigned forged Google token without credentials", async () => {
  const app = initializeApp({ projectId: "demo-nospace-wallet" }, "auth-negative-test");
  const encode = (value: unknown): string => Buffer.from(JSON.stringify(value)).toString("base64url");
  const forged = `${encode({ alg: "none", typ: "JWT" })}.${encode(claims())}.`;
  try {
    await assert.rejects(requireGooglePrincipal(`Bearer ${forged}`, getAuth(app)), AuthenticationError);
  } finally {
    await deleteApp(app);
  }
});
