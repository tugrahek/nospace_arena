import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.Signature;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.Locale;
import java.util.jar.JarFile;

/** Read-only key inspection and pinned-signer verification. Never emits provider errors. */
class UploadKeyPreflight {
    private static final String PREFIX = "GODOT_ANDROID_KEYSTORE_RELEASE_";

    private static void reject(String code) {
        System.out.println(code);
        System.exit(2);
    }

    public static void main(String[] args) {
        char[] password = null;
        try {
            String secret = System.getenv(PREFIX + "PASSWORD");
            if (secret == null || secret.isEmpty()) reject("MISSING_ENV");
            password = secret.toCharArray();
            String expected = System.getenv("NOSPACE_UPLOAD_CERT_SHA256");
            if (args.length == 2 && args[0].equals("verify")) {
                verifyBundle(Path.of(args[1]), expected);
                System.out.println("VERIFIED");
                return;
            }
            KeyStore store;
            try {
                store = KeyStore.getInstance(Path.of(System.getenv(PREFIX + "PATH")).toFile(), password);
            } catch (Exception error) {
                reject("KEYSTORE_INVALID");
                return;
            }
            String alias = System.getenv(PREFIX + "USER");
            if (!store.entryInstanceOf(alias, KeyStore.PrivateKeyEntry.class)) reject("ALIAS_NOT_PRIVATE");
            if (!(store.getCertificate(alias) instanceof X509Certificate)) reject("CERT_INVALID");
            X509Certificate cert = (X509Certificate) store.getCertificate(alias);
            cert.checkValidity();
            if (cert.getSubjectX500Principal().getName().toLowerCase(Locale.ROOT).contains("android debug")) {
                reject("DEBUG_CERTIFICATE");
            }
            if (!fingerprint(cert).equals(expected)) reject("CERT_MISMATCH");
            PrivateKey key = (PrivateKey) store.getKey(alias, password);
            if (key == null || !key.getAlgorithm().equals("RSA") ||
                    !(((java.security.interfaces.RSAKey) key).getModulus().bitLength() >= 2048)) {
                reject("KEY_UNUSABLE");
            }
            // Prove the private key unlocks with Godot's shared store/key password.
            byte[] challenge = new byte[32];
            new java.security.SecureRandom().nextBytes(challenge);
            Signature signature = Signature.getInstance("SHA256withRSA");
            signature.initSign(key);
            signature.update(challenge);
            byte[] proof = signature.sign();
            signature.initVerify(cert);
            signature.update(challenge);
            if (!signature.verify(proof)) reject("KEY_UNUSABLE");
            System.out.println("READY");
        } catch (Exception error) {
            reject("KEY_UNUSABLE");
        } finally {
            if (password != null) Arrays.fill(password, '\0');
        }
    }

    private static String fingerprint(X509Certificate cert) throws Exception {
        return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(cert.getEncoded()));
    }

    private static void verifyBundle(Path bundle, String expected) throws Exception {
        try (JarFile jar = new JarFile(bundle.toFile(), true)) {
            var entries = jar.entries();
            int count = 0;
            while (entries.hasMoreElements()) {
                var entry = entries.nextElement();
                if (entry.isDirectory()) continue;
                try (InputStream stream = jar.getInputStream(entry)) {
                    stream.transferTo(java.io.OutputStream.nullOutputStream());
                }
                String name = entry.getName().toUpperCase(Locale.ROOT);
                if (name.equals("META-INF/MANIFEST.MF") || (name.startsWith("META-INF/") &&
                        name.matches("META-INF/[^/]+\\.(SF|RSA|DSA|EC)"))) continue;
                var signers = entry.getCodeSigners();
                if (signers == null || signers.length != 1) reject("KEY_UNUSABLE");
                X509Certificate cert = (X509Certificate) signers[0].getSignerCertPath().getCertificates().get(0);
                if (!fingerprint(cert).equals(expected)) reject("CERT_MISMATCH");
                count++;
            }
            if (count == 0) reject("KEY_UNUSABLE");
        }
    }
}
