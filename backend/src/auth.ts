import type { Auth } from "firebase-admin/auth";

/** Narrow injection boundary: production must supply Firebase Admin Auth. */
export type TokenVerifier = Pick<Auth, "verifyIdToken">;
export interface WalletPrincipal {
  readonly uid: string;
  readonly provider: "google.com";
}

/** Deliberately omits token contents, verifier errors and user identifiers. */
export class AuthenticationError extends Error {
  constructor() {
    super("unauthenticated");
    this.name = "AuthenticationError";
  }
}

/** Verifies project/signature/expiry via Admin, checks revocation and Google sign-in. */
export async function requireGooglePrincipal(
  authorization: unknown,
  auth: TokenVerifier,
): Promise<WalletPrincipal> {
  if (typeof authorization !== "string" || authorization.trim() !== authorization ||
      !/^Bearer [^\s]+$/.test(authorization)) {
    throw new AuthenticationError();
  }
  try {
    const claims = await auth.verifyIdToken(authorization.slice("Bearer ".length), true);
    if (claims.firebase.sign_in_provider !== "google.com" ||
        typeof claims.uid !== "string" || claims.uid.trim().length === 0 ||
        claims.uid.length > 128 || claims.uid.includes("/") ||
        claims.uid === "." || claims.uid === "..") {
      throw new AuthenticationError();
    }
    return Object.freeze({ uid: claims.uid, provider: "google.com" });
  } catch {
    throw new AuthenticationError();
  }
}
