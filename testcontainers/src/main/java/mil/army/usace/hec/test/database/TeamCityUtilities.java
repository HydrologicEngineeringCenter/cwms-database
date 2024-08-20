package mil.army.usace.hec.test.database;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class TeamCityUtilities {
    public static String cleanupBranchName(String branchName){
        String name =  branchName.replace("/","_")
                                 .replace("/refs/heads/","")
                                 .replace("-","_")
                                 .replace("#","_");
        
        return md5(name);
    }

    public static String volumeName(String prefix, String ...elements) {
        String combined = String.join("_", elements);

        return prefix + "_" + md5(combined);
    }

    /**
     * The generate names do not need to be cryptographically secure, just suitable
     * for volume and domain names
     * @param input
     * @return
     */
    private static String md5(String input) {
        
        try {
            MessageDigest md5Digest = MessageDigest.getInstance("MD5");
            md5Digest.update(input.getBytes());
            byte digest[] = md5Digest.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b: digest) {
                sb.append(String.format("%02x",b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException ex) {
            throw new RuntimeException("Unable to create digest", ex);
        }
        
    }
}
