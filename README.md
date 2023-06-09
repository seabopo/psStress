# psStress
A PowerShell module for basic CPU and Memory stressing. It includes a web server for viewing the container logs
and some basic test controls. It was created primarily to test and debug Windows-based AKS pods. 
A Windows Nano Server image of this module is available here: 
[seabopo/psstress](https://hub.docker.com/repository/docker/seabopo/psstress/general)

The full parameter list can be viewed in the 
[/public/Start-Stressing.ps1](https://github.com/seabopo/psStress/blob/main/public/Start-Stressing.ps1) 
file, which is the module's main entrypoint.

A variety of Windows and Docker usage examples are available in the 
[/psStress-tests.ps1](https://github.com/seabopo/psStress/blob/main/psStress-tests.ps1) file.
