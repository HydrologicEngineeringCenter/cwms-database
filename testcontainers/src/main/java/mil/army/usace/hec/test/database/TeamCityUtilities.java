package mil.army.usace.hec.test.database;

public class TeamCityUtilities {
    public static String cleanupBranchName(String branchName){
        return branchName.replace("/","_")
                         .replace("/refds/heads/","")
                         .replace("-","_")
                         .replace("#","_");
    }
}
