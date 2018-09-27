// Edit dockertest but otherwise do not edit 
// Automatically generated from the following template in wrsinc/etc:
// https://github.com/wrsinc/etc/blob/master/roles/jenkins/templates/Jenkinsfile.j2
//
// The following ENV VARS must be set in Jenkins:
//
// BLUEOCEAN_PIPELINE_URL=https://test.polarisdev.io/blue/organizations/jenkins
// GCLOUD_PROJECTS
// OPS_NPM_TOKEN
// WRSINC_GITHUB_USERNAME
// WRSINC_GITHUB_API_TOKEN

// Function to determine GCP Project for use in ruby script
def gcpProject(branch) {
  if (branch == 'develop'){
    return 'poc-tier1'
  } else if (branch == 'master'){
    return 'staging-tier1'
  } else {
    return 'scratch'
  }
}
// Determine shortsha for app to be used by kubernetes-deploy
def revision() {
  return sh (
    script: 'git rev-parse --short HEAD',
    returnStdout: true
  ).trim()
}

// A Declarative Pipeline is defined within a 'pipeline' block.
pipeline {
  // agent defines where the pipeline will run.

  agent {
    // This also could have been 'agent any' - that has the same meaning.

    label 'k8s'
    // Other possible built-in agent types are 'agent none', for not running the
    // top-level on any agent (which results in you needing to specify agents on
    // each stage and do explicit checkouts of scm in those stages), 'docker',
    // and 'dockerfile'.
  }

  environment {
    // Environment variable identifiers need to be both valid bash variable
    // identifiers and valid Groovy variable identifiers. If you use an invalid
    // identifier, you'll get an error at validation time.
    // Right now, you can't do more complicated Groovy expressions or nesting of
    // other env vars in environment variable values, but that will be possible
    // when https://issues.jenkins-ci.org/browse/JENKINS-41748 is merged and
    // released.

    ACTIVITY_URL = "${BLUEOCEAN_PIPELINE_URL}/dockertest/activity"
    GCP_PROJECT = gcpProject(env.BRANCH_NAME)
    REVISION = revision()
    KUBECONFIG = '~/.kube/config'
  }

  options {
    // Set a timeout period for the Pipeline run, after which Jenkins should
    // abort the Pipeline.

    timestamps()
    timeout(time: 30, unit: 'MINUTES')
  }

  stages {
    // At least one stage is required.

    stage('Preparation') {
      // prepare for building and deployment by downloading shared scripts
      steps {
        dir(pwd(tmp: true)) {
          git branch: 'master', url: 'https://github.com/wrsinc/kubedeploy', credentialsId: 'd6d6810c-6202-4311-8550-dbc0655f818e'
          stash name: 'kubedeploy'
        }
        dir('omdeploy') {
          git branch: 'master', url: 'https://github.com/wrsinc/omdeploy.git', credentialsId: 'd6d6810c-6202-4311-8550-dbc0655f818e'
        }
      }
    }

    stage('Test') {
      // You can override tools, environment and agent on each stage if you want.

      steps {
        configFileProvider([
          configFile(fileId: 'settings.xml', variable: 'SETTINGS')
        ]) {
          sh 'STAGE=test ruby omdeploy/scripts/omdeploy.rb'
        }
      }
    }

    stage('Build') {
      // Every stage must have a steps block containing at least one step.

      steps {
        script {
          job_name = sh(
            returnStdout: true,
            script: """
              echo ${JOB_NAME} \
              | sed -e 's|/|/detail/|'
            """
          ).trim()
        }
        script {
          BLUEOCEAN_URL = sh(
            returnStdout: true,
            script: """
              echo "${BLUEOCEAN_PIPELINE_URL}/${job_name}/${BUILD_NUMBER}/pipeline/"
            """
          ).trim()
        }

        configFileProvider([
          configFile(fileId: 'settings.xml', variable: 'SETTINGS')
        ]) {
          sh 'STAGE=build ruby omdeploy/scripts/omdeploy.rb'
        }
      }
    }

    stage('*** Deploy *** poc-tier1') {
      when {
        branch 'develop'
      }

      steps {
        configFileProvider([
          configFile(
            fileId: 'ejson-keys-poc-tier1.yaml',
            variable: 'EJSON_KEYS_YAML'
          ),
          configFile(
            fileId: 'gcloud-service-account-credentials-poc-tier1.json',
            variable: 'GCLOUD_SERVICE_ACCOUNT_CREDENTIALS'
          )
        ]) {
          sh 'STAGE=deploy ruby omdeploy/scripts/omdeploy.rb'
        }

        unstash name: 'kubedeploy'
        sh './newrelic_send_deployment_info poc-tier1 "$PWD"'
      }
    }

    stage('*** Deploy *** staging-tier1') {
      when {
        branch 'master'
      }

      steps {
        configFileProvider([
          configFile(
            fileId: 'ejson-keys-staging-tier1.yaml',
            variable: 'EJSON_KEYS_YAML'
          ),
          configFile(
            fileId: 'gcloud-service-account-credentials-staging-tier1.json',
            variable: 'GCLOUD_SERVICE_ACCOUNT_CREDENTIALS'
          )
        ]) {
          sh 'STAGE=deploy ruby omdeploy/scripts/omdeploy.rb'
        }

        unstash name: 'kubedeploy'
        sh './newrelic_send_deployment_info staging-tier1 "$PWD"'
      }
    }
  }

  post {
    // Always runs at end of job


    success {
      slackSend (
        color: (
          BRANCH_NAME == ('master' || 'develop') ?
            "#326de6" :
            "#228B22"
        ),
        message: (
          BRANCH_NAME == 'master' ?
            "Job: ${JOB_NAME} [${BUILD_NUMBER}] *SUCCESS*\nLog: ${BLUEOCEAN_URL}\nDeployment: _staging-tier1_ " : (
              BRANCH_NAME == 'develop' ?
                "Job: ${JOB_NAME} [${BUILD_NUMBER}] *SUCCESS*\nLog: ${BLUEOCEAN_URL}\nDeployment: _poc-tier1_ " : (
                  "${env.CHANGE_TITLE}" == "null" ?
                    "Job: ${JOB_NAME} [${BUILD_NUMBER}] *SUCCESS*\nLog: ${BLUEOCEAN_URL}\n" :
                    "Job: ${JOB_NAME} [${BUILD_NUMBER}] *SUCCESS*\nLog: ${BLUEOCEAN_URL}\nPR: \"${env.CHANGE_TITLE}\", ${env.CHANGE_AUTHOR_DISPLAY_NAME}, ${env.CHANGE_URL}\n"
                )
            )
        )
      )
    }

    failure {
      slackSend (
        color: "#8B0000",
        message: (
          BRANCH_NAME == 'master' ?
            "Job: ${JOB_NAME} [${BUILD_NUMBER}] *FAILURE*\nLog: ${BLUEOCEAN_URL}\nDeployment: _staging-tier1_ " : (
              BRANCH_NAME == 'develop' ?
                "Job: ${JOB_NAME} [${BUILD_NUMBER}] *FAILURE*\nLog: ${BLUEOCEAN_URL}\nDeployment: _poc-tier1_ " : (
                  "${env.CHANGE_TITLE}" == "null" ?
                    "Job: ${JOB_NAME} [${BUILD_NUMBER}] *FAILURE*\nLog: ${BLUEOCEAN_URL}\n" :
                    "Job: ${JOB_NAME} [${BUILD_NUMBER}] *FAILURE*\nLog: ${BLUEOCEAN_URL}\nPR: \"${env.CHANGE_TITLE}\", ${env.CHANGE_AUTHOR_DISPLAY_NAME}, ${env.CHANGE_URL}\n"
                )
            )
        )
      )
    }
  }
}