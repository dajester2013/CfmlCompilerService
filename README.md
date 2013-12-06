RailoCompilerService
====================

Webservice for building sourceless deployments of Railo CFML projects.

### Build

 * WAR (for deployment into a servlet already configured to run Railo)
Run: ant war
Produces: dist/war/rcs.war

 * WAR - Standalone (for deployment into a general servlet container)
Run: ant war-standalone
Produces: dist/war-standalone/rcs.war