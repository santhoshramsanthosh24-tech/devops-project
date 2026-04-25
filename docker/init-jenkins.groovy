import jenkins.model.Jenkins
import hudson.security.SecurityRealm
import hudson.security.AuthorizationStrategy
import jenkins.security.s2m.AdminWhitelistRule

// Disable setup wizard
System.setProperty("jenkins.install.runSetupWizard", "false")

// Get Jenkins instance
def jenkins = Jenkins.getInstance()

// Disable CSRF protection for simplified setup
jenkins.setCrumbIssuer(null)

// Allow script approval
jenkins.getExtensionList('hudson.security.csrf.CrumbIssuer').each {
    it.getDescriptor()?.store()
}

// Set executor count
jenkins.setNumExecutors(2)

// Save configuration
jenkins.save()

println("Jenkins initialized - setup wizard disabled")
