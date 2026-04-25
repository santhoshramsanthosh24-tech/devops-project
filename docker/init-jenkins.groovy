import jenkins.model.Jenkins
import hudson.security.SecurityRealm
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.security.HudsonPrivateSecurityRealm

def jenkins = Jenkins.getInstance()

// Disable setup wizard
System.setProperty("hudson.model.UpdateCenter.never", "true")

// Get or create the security realm
def realm = jenkins.getSecurityRealm()
if (realm instanceof HudsonPrivateSecurityRealm) {
    def adminUser = realm.getUser("admin")
    if (adminUser != null) {
        // Update existing admin password
        adminUser.setPassword("Admin@123456")
        realm.saveUser(adminUser)
    }
} else {
    // Create new HudsonPrivateSecurityRealm if it doesn't exist
    realm = new HudsonPrivateSecurityRealm(true, false)
    jenkins.setSecurityRealm(realm)
    
    // Create admin user
    def adminUser = realm.createAccount("admin", "Admin@123456")
    realm.saveUser(adminUser)
}

// Set authorization strategy
def authStrategy = new FullControlOnceLoggedInAuthorizationStrategy()
jenkins.setAuthorizationStrategy(authStrategy)

// Set number of executors
jenkins.setNumExecutors(2)

// Disable CSRF protection
jenkins.setCrumbIssuer(null)

// Save configuration
jenkins.save()

println("Jenkins initialized successfully")
println("Admin user configured: admin")

