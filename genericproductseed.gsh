import groovy.json.*
/**
Copyright : Manivannan Radhakannan.
This file contains code to 
 1. Generate Jenkin seeds from JSON file as input
 2. JSON File contains the steps and configuration for a Jenkins Job

Purpose:
 To create Jenkins seed to trigger jobs for different variants of the same product

prd name: You can specify different product names like [SW_AMERICA] [SW_EUROPE]
branches: Release branch, development branch, test branch etc
Downstream Job Types: performance , regression and Test Report

**/


class prdGenerator {
    /**
    def prdname = ["ABC"]
    def branches = ["release", "master","refactoring"]
    def jobtypes = ["performance", "regression","TestReport"]
    def preferrednode = "master"
    def workdir = "/home/<location to scripts,json,groovy>"
    def inputJSON = "NULL"

    def getJSONText(String fileUrl) {
      return new JsonSlurper().parseText((new File(fileUrl)).getText())
    }
}


def prdObj = new prdGenerator()
def downstreamObj = new prdGenerator()

def branchText = prdObj.getJSONText("/home/<scriptlocation>/release.json")

for(int prdindex = 0; prdindex < prdObj.prdname.size(); prdindex++) {

      for(int brnindex = 0; brnindex < prdObj.branches.size(); brnindex++) {

          createBranchJob(prdObj.prdname[prdindex],prdObj.branches[brnindex],branchText,prdObj)

          for(int jobtypeindex = 0;jobtypeindex < prdObj.jobtypes.size();jobtypeindex++) {
            def downStreamText = prdObj.getJSONText("/home/<scriptlocation>/" + prdObj.jobtypes[jobtypeindex] + ".json")
            createDownstreamJob(prdObj.prdname[prdindex],prdObj.branches[brnindex],prdObj.jobtypes[jobtypeindex],downStreamText)
          }
      }
}


def createBranchJob(prdName,brnName,jsonObj, prdObj)
{
  job(prdName+"_"+brnName) {

    label(jsonObj.jenkinsurltriggers[1])
       triggers {
          urlTrigger {
             cron(jsonObj.jenkinsurltriggers[0])
             restrictToLabel(jsonObj.jenkinsurltriggers[1])
          }
       }
    scm {
          git {
            remote {
              name(prdName)
              url(jsonObj.gitarguments[1])
              credentials(jsonObj.gitarguments[2])
              branch("*/"+brnName)
            }
          }
        }


    wrappers {
      environmentVariables {
        propertiesFile(jsonObj.environmentVariables)
      }
      timestamps()
      timeout {
        absolute(Integer.parseInt(jsonObj.timeoutarguments[0]))
        writeDescription(jsonObj.timeoutarguments[1])
	  }
    }

    steps {

      shell(readFileFromWorkspace(jsonObj.shellscript))
      copyArtifacts(brnName) {
        targetDirectory(jsonObj.targetDirectory)
        includePatterns(jsonObj.includepatterns)
        fingerprintArtifacts(true)
        buildSelector {
          latestSuccessful(true)
        }
      }
    }

    publishers {
      def downstreamstring = ""
      // down
      for(int jobtypeindex = 0;jobtypeindex < prdObj.jobtypes.size();jobtypeindex++) {
            downstreamstring = downstreamstring + prdName + "_" + brnName + "_" + prdObj.jobtypes[jobtypeindex] + ","
        }

      downstream(downstreamstring, 'SUCCESS')
      publishBuild {
        discardOldBuilds(7, 20)
        publishFailed(false)
        publishUnstable(false)
      }
      archiveArtifacts {
        pattern(jsonObj.archiveartifacts)
      }

      plotBuildData {
        plot(jsonObj.plotcolumnargs[0], jsonObj.plotcolumnargs[1]) {
          title(jsonObj.plotargs1[0])
          style(jsonObj.plotargs1[1])
          yAxis(jsonObj.plotargs1[2])
          numberOfBuilds(Integer.parseInt(jsonObj.plotargs1[3]))
          useDescriptions()
          csvFile(jsonObj.plotcolumnargs[1]) {
            label(jsonObj.jenkinsurltriggers[1])
          }
        }
      }

      buildDescription('Release-Version: ([^\\s]*)','Version: \\1')
      archiveJunit(jsonObj.archiveJunit[0])

    }


  }// create job
}


def createDownstreamJob(prdName,brnName,downstreamName,jsonObj)
{
  println prdName+"_"+brnName+"_"+downstreamName
  job(prdName+"_"+brnName+"_"+downstreamName) {


    if (!((jsonObj.jenkinsurltriggers[0] == "") || (jsonObj.jenkinsurltriggers[0] == "NULL"))) {
      label(jsonObj.jenkinsurltriggers[1])
         triggers {
            urlTrigger {
               cron(jsonObj.jenkinsurltriggers[0])
               restrictToLabel(jsonObj.jenkinsurltriggers[1])
            }
         }
    }

    if (!((jsonObj.gitarguments[0] == "") || (jsonObj.gitarguments[0] == "NULL"))) {
      scm {
            git {
              remote {
                name(prdName)
                url(jsonObj.gitarguments[1])
                credentials(jsonObj.gitarguments[2])
                branch(prdName+"_"+brnName)
              }
            }
        }
    }


    if (!((jsonObj.environmentVariables == "") || (jsonObj.environmentVariables == "NULL"))) {
      wrappers {
        environmentVariables {
            propertiesFile(jsonObj.environmentVariables)
            }
            timestamps()
            timeout {
                absolute(Integer.parseInt(jsonObj.timeoutarguments[0]))
                writeDescription(jsonObj.timeoutarguments[1])
            }
        }
    }


    steps {

      if (!((jsonObj.shellscript == "") || (jsonObj.shellscript == "NULL"))) {
        shell(readFileFromWorkspace(jsonObj.shellscript))
      }

      if (!((jsonObj.targetDirectory == "") || (jsonObj.targetDirectory == "NULL"))) {
        copyArtifacts(prdName+"_"+brnName) {
            targetDirectory(jsonObj.targetDirectory)
            includePatterns(jsonObj.includepatterns)
            fingerprintArtifacts(true)
            buildSelector {
            latestSuccessful(true)
          }

        }
      }
    }


    publishers {

      publishBuild {
        discardOldBuilds(7, 20)
        publishFailed(false)
        publishUnstable(false)
      }

      if (!((jsonObj.archiveartifacts == "") || (jsonObj.archiveartifacts == "NULL"))) {
        archiveArtifacts {
          pattern(jsonObj.archiveartifacts)
        }
      }

      // before using any variable check if the value is null or empty
      if (!((jsonObj.plotcolumnargs[0] == "") || (jsonObj.plotcolumnargs[0] == "NULL"))) {
        plotBuildData {
            plot(jsonObj.plotcolumnargs[0], jsonObj.plotcolumnargs[1]) {
                title(jsonObj.plotargs1[0])
                style(jsonObj.plotargs1[1])
                yAxis(jsonObj.plotargs1[2])
                numberOfBuilds(Integer.parseInt(jsonObj.plotargs1[3]))
                useDescriptions()
                csvFile(jsonObj.plotcolumnargs[1]) {
                    label(jsonObj.jenkinsurltriggers[1])
                    }
                }
            }
        }// end of IF statement

      if (!((jsonObj.plotargs2[0] == "") || (jsonObj.plotargs2[0] == "NULL"))) {
          plotBuildData {
            plot(jsonObj.plotcolumnargs[0], jsonObj.plotcolumnargs[1]) {
              title(jsonObj.plotargs2[0])
              style(jsonObj.plotargs2[1])
              yAxis(jsonObj.plotargs2[2])
              numberOfBuilds(Integer.parseInt(jsonObj.plotargs2[3]))
              useDescriptions()
              csvFile(jsonObj.plotcolumnargs[1]) {
                label(jsonObj.jenkinsurltriggers[1])
              }
            }
          }
      }


      buildDescription('Release-Version: ([^\\s]*)','Version: \\1')
      if (!((jsonObj.archiveJunit[0] == "") || (jsonObj.archiveJunit[0] == "NULL"))) {
        archiveJunit(jsonObj.archiveJunit[0])
      }

    }

  }// create job
}
